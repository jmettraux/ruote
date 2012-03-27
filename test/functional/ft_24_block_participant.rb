
#
# testing ruote
#
# Tue Aug 11 13:56:28 JST 2009
#

require File.expand_path('../base', __FILE__)


class FtBlockParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitems_dispatching_message

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'v0', :val => 'v0val'
        set :field => 'f0', :val => 'f0val'
        alpha
        bravo
        charly
      end
    end

    @dashboard.register_participant :alpha do
      tracer << "a\n"
    end
    @dashboard.register_participant :bravo do |workitem|
      tracer << "b:f0:#{workitem.fields['f0']}\n"
    end
    @dashboard.register_participant :charly do |workitem, fexp|
      tracer << "c:f0:#{workitem.fields['f0']}:#{fexp.lookup_variable('v0')}\n"
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal "a\nb:f0:f0val\nc:f0:f0val:v0val", @tracer.to_s
  end

  TEST_BLOCK = Ruote.process_definition do
    sequence do
      alpha
      echo '${f:__result__}'
    end
  end

  def test_block_result

    return if Ruote::WIN or Ruote::JAVA
      # defective 'json' lib on windows render this test useless

    @dashboard.register_participant :alpha do |workitem|
      'seen'
    end

    #noisy

    assert_trace 'seen', TEST_BLOCK
  end

  def test_non_jsonfiable_result

    return if Ruote::WIN
      # defective 'json' lib on windows renders this test useless

    @dashboard.register_participant :alpha do |workitem|
      Time.now
    end

    #noisy

    match = if defined?(DataMapper) && DataMapper::VERSION < '1.0.0'
      /^$/
    else
      /\b#{Time.now.year}\b/
    end

    wfid = @dashboard.launch(TEST_BLOCK)

    @dashboard.wait_for(wfid)

    assert_match match, @tracer.to_s
  end

  def test_raise_security_error_before_evaluating_rogue_code

    fn = "test/bad.#{Time.now.to_f}.txt"

    @dashboard.participant_list = [
      #[ 'alpha', [ 'Ruote::BlockParticipant', { 'block' => 'exit(3)' } ] ]
      [ 'alpha', [ 'Ruote::BlockParticipant', { 'block' => "proc { File.open(\"#{fn}\", \"wb\") { |f| f.puts(\"bad\") } }" } ] ]
    ]

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define { alpha })

    @dashboard.wait_for(wfid)
    sleep 0.300

    assert_equal false, File.exist?(fn), 'security check not enforced'

    assert_equal 1, @dashboard.errors(wfid).size
    assert_match /SecurityError/, @dashboard.errors(wfid).first.message

    FileUtils.rm(fn) rescue nil
  end

  def test_raise_security_error_upon_registering_rogue_block_participant

    assert_raise Rufus::SecurityError do

      @dashboard.register 'rogue' do |workitem|
        workitem.content = File.read('test/nada.txt')
      end
    end
  end

  # cf https://github.com/jmettraux/ruote/issues/30
  #
  def test_begin_rescue_end

    @dashboard.register 'rogue' do |workitem|
      begin
      rescue => e
      end
    end

    assert true
  end

  def test_on_cancel_registration

    @dashboard.register 'nemo',
      :on_workitem => lambda { |wi|
        p wi
      },
      :on_cancel => lambda { |fei, flavour|
        p fei, flavour
      }

    assert_equal(
      { 'on_cancel' => "proc { |fei, flavour|\n        p fei, flavour\n      }",
        'on_workitem' => "proc { |wi|\n        p wi\n      }" },
      @dashboard.participant_list.first.options)
  end

  def test_on_cancel

    @dashboard.register 'sleeper',
      :on_workitem => lambda { |workitem|
        context.tracer << "consumed\n"
        sleep 60 # preventing the implicit reply_to_engine(workitem)
      },
      :on_cancel => lambda { |fei, flavour|
        context.tracer << "cancelled\n"
      }

    pdef = Ruote.define do
      sleeper
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:sleeper)
    sleep 0.350

    assert_equal 'consumed', @tracer.to_s

    @dashboard.cancel(wfid)

    @dashboard.wait_for(wfid)

    assert_equal "consumed\ncancelled", @tracer.to_s
  end

  def test_on_reply

    @dashboard.register 'consumer',
      :on_workitem => lambda { |workitem|
        context.tracer << "consumed\n"
      },
      :on_reply => lambda { |workitem|
        context.tracer << "replied\n"
      }

    pdef = Ruote.define do
      consumer
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal "consumed\nreplied", @tracer.to_s
  end

  def test_accept

    @dashboard.register 'consumer',
      :on_workitem => lambda { |workitem|
        raise 'fail miserably'
      },
      :accept? => lambda { |workitem|
        false
      }

    pdef = Ruote.define do
      consumer
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_match /unknown participant/, @dashboard.ps(wfid).errors.first.message
  end

  def test_do_not_thread

    @dashboard.register 'consumer',
      :on_workitem => lambda { |workitem|
        context.tracer << "in\n"
      },
      :do_not_thread => lambda { |workitem|
        context.tracer << "dnt\n"
        false
      }

    pdef = Ruote.define do
      consumer
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(:consumer)

    sleep 0.350

    assert_equal "dnt\nin", @tracer.to_s
  end

  def test_block_with_methods

    @dashboard.register 'consumer' do
      on_workitem do
        context.tracer << "on_workitem\n"
      end
      on_cancel do
        context.tracer << "on_cancel\n"
      end
    end

    assert_equal(
      %w[ on_cancel on_workitem ],
      @dashboard.participant_list[0].options.keys.sort)

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      consumer
    end)
    @dashboard.wait_for(wfid)

    assert_equal 'on_workitem', @tracer.to_s
  end

  def test_block_with_methods_2

    @dashboard.register do

      consumer do

        on_workitem do
          context.tracer << "on_workitem\n"
        end
        on_cancel do
          context.tracer << "on_cancel\n"
        end
      end
    end

    assert_equal(
      %w[ on_cancel on_workitem ],
      @dashboard.participant_list[0].options.keys.sort)
  end
end

