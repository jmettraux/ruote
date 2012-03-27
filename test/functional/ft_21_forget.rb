
#
# testing ruote
#
# Mon Jul 27 09:17:51 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtForgetTest < Test::Unit::TestCase
  include FunctionalBase

  def test_basic

    pdef = Ruote.process_definition do
      sequence do
        alpha :forget => true
        alpha
      end
    end

    @dashboard.register_participant :alpha do
      tracer << "alpha\n"
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)
    wait_for(wfid)

    assert_equal %w[ alpha alpha ].join("\n"), @tracer.to_s

    #logger.log.each { |e| p e }

    assert_equal 1, logger.log.select { |e| e['action'] == 'ceased' }.size
    assert_equal 1, logger.log.select { |e| e['action'] == 'terminated' }.size
  end

  def test_forgotten_tree

    sp = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      sequence do
        alpha :forget => true
      end
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_not_nil ps
    assert_equal 0, ps.errors.size
    assert_equal 1, ps.expressions.size

    fei = ps.expressions.first.fei
    assert_equal fei, ps.root_expression_for(fei).fei
  end

  def test_forget_true_string

    pdef = Ruote.process_definition do
      concurrence :count => 1 do
        alpha :forget => 'true'
        bravo
      end
      charly
    end

    @dashboard.register_participant '.+' do |wi|
      tracer << wi.participant_name + "\n"
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)
    wait_for(wfid)

    assert_equal %w[ alpha bravo charly ], @tracer.to_a.sort
  end

  def test_forget_and_cursor

    pdef = Ruote.define do
      cursor do
        alpha :forget => true
        bravo
        rewind
      end
    end

    @dashboard.register_participant 'alpha', Ruote::NullParticipant
      # this participant never replies

    @dashboard.register_participant 'bravo', Ruote::NoOpParticipant
      # this one simply replies

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:bravo)
    @dashboard.wait_for(:bravo)

    assert_not_nil @dashboard.process(wfid)
  end

  # As reported by Nando Sola
  #
  # http://groups.google.com/group/openwferu-users/browse_thread/thread/50308e9dce8359e6
  #
  def test_forget_on_forget

    pdef = Ruote.define do
      concurrence do
        listen :to => 'bravo', :upon =>'reply', :wfid => true do
          sequence :forget => true do
            alpha
          end
        end
        bravo
      end
    end

    @dashboard.register do
      catchall Ruote::NoOpParticipant
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal(
      [],
      @dashboard.history.all.select { |e| e['action'] == 'error_intercepted' })
  end
end

