
#
# testing ruote
#
# Fri Jun 19 15:26:33 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftListenTest < Test::Unit::TestCase
  include FunctionalBase

  def test_listen

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          listen :to => '/^al.*/'
          echo '1'
        end
        sequence do
          alpha
        end
      end
    end

    @dashboard.register_participant :alpha do
      tracer << "alpha\n"
    end

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    assert_equal %w[ 1 alpha ], @tracer.to_a.sort

    assert_equal(
      0,
      @dashboard.context.storage.get('variables', 'trackers')['trackers'].size)
  end

  def test_listen_with_child

    pdef = Ruote.process_definition do
      concurrence do
        listen :to => /^al.*/ do
          bravo
        end
        sequence do
          alpha
          alpha
        end
      end
    end

    @dashboard.register_participant :alpha do
      tracer << "a\n"
    end
    @dashboard.register_participant :bravo do |workitem|
      tracer << "#{workitem.fei.wfid}|#{workitem.fei.subid}"
      tracer << "\n"
    end

    wfid = @dashboard.launch(pdef)

    4.times { @dashboard.wait_for('dispatched') }

    a = @tracer.to_a
    assert_equal 2, a.select { |e| e == 'a' }.size

    a = (a - [ 'a', 'a' ]).sort
    assert_equal 2, a.uniq.size

    ps = @dashboard.process(wfid)

    #assert_equal 3, ps.expressions.size
    assert_equal 0, ps.errors.size

    assert_equal(
      1,
      @dashboard.context.storage.get('variables', 'trackers')['trackers'].size)
  end

  def test_upon

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          listen :to => /^al.*/, :merge => false
          bravo
        end
        sequence do
          listen :to => '/^al.*/', :upon => 'reply'
          bravo
        end
        sequence do
          alpha
        end
      end
    end

    @dashboard.register_participant :alpha do |workitem|
      tracer << "alpha\n"
      workitem.fields['seen'] = 'yes'
    end
    @dashboard.register_participant :bravo do |workitem|
      tracer << "bravo:#{workitem.fields['seen']}\n"
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal %w[ alpha bravo: bravo:yes ], @tracer.to_a.sort
  end

  def test_merge_override

    pdef = Ruote.process_definition do
      set :f => 'name', :val => 'Kilroy'
      set :f => 'other', :val => 'nothing'
      concurrence do
        sequence do
          listen :to => '/^al.*/', :merge => 'override', :upon => 'reply'
          bravo
        end
        sequence do
          alpha
        end
      end
    end

    @dashboard.register_participant :alpha do |wi|
      tracer << "alpha\n"
      wi.fields['name'] = 'William Mandella'
    end
    @dashboard.register_participant :bravo do |wi|
      tracer << "name:#{wi.fields['name']} "
      tracer << "other:#{wi.fields['other']}\n"
    end

    assert_trace("alpha\nname:William Mandella other:nothing", pdef)
  end

  def test_where

    pdef = Ruote.process_definition do
      concurrence do
        listen :to => 'alpha', :where => '${f:who} == toto', :upon => 'reply' do
          echo 'toto'
        end
        sequence do
          alpha
        end
        sequence do
          alpha
        end
      end
    end

    stash[:count] = 0

    @dashboard.register_participant :alpha do |wi|
      tracer << "alpha\n"
      wi.fields['who'] = 'toto' if context.stash[:count] > 0
      context.stash[:count] += 1
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid) # ceased

    assert_equal %w[ alpha alpha toto ].join("\n"), @tracer.to_s
    assert_equal 3, @dashboard.process(wfid).expressions.size

    assert_not_nil(
      @dashboard.context.logger.log.find { |l| l['action'] == 'ceased' })
  end

  def test_listen_cancel

    pdef = Ruote.process_definition do
      listen :to => 'alpha'
    end

    wfid = @dashboard.launch(pdef)

    wait_for(2)

    assert_equal(
      1, @dashboard.context.storage.get('variables', 'trackers')['trackers'].size)

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_equal(
      0, @dashboard.context.storage.get('variables', 'trackers')['trackers'].size)
  end

  def test_cross

    listening = Ruote.process_definition do
      sequence do
        listen :to => 'alpha'
        echo 'ldone.'
      end
    end
    emitting = Ruote.process_definition do
      sequence do
        alpha
        echo 'edone.'
      end
    end

    @dashboard.register_participant :alpha do
      # nothing
    end

    lwfid = @dashboard.launch(listening)
    ewfid = @dashboard.launch(emitting)

    wait_for(lwfid, ewfid)

    #assert_equal("edone.\nldone.", @tracer.to_s)
    assert_equal %w[ edone. ldone. ], @tracer.to_a.sort
  end

  def test_not_cross

    listening = Ruote.process_definition do
      sequence do
        listen :to => 'alpha', :wfid => :same
        echo 'ldone.'
      end
    end
    emitting = Ruote.process_definition do
      sequence do
        alpha
        echo 'edone.'
      end
    end

    @dashboard.register_participant :alpha do
      # nothing
    end

    lwfid = @dashboard.launch(listening)
    ewfid = @dashboard.launch(emitting)

    wait_for(ewfid)

    assert_equal("edone.", @tracer.to_s)

    ps = @dashboard.process(lwfid)
    assert_equal(3, ps.expressions.size)
  end

  def test_listen_to_tag

    listening = Ruote.process_definition do
      concurrence do
        listen :to => :first_phase, :upon => :leaving do
          echo 'left'
        end
        listen :to => :first_phase, :upon => :entering do
          echo 'entered'
        end
      end
    end
    emitting = Ruote.process_definition do
      sequence :tag => :first_phase do
        echo 'in'
      end
      echo 'edone.'
    end

    lwfid = @dashboard.launch(listening)
    ewfid = @dashboard.launch(emitting)

    wait_for(ewfid)

    assert_equal(%w[ in entered edone. left ], @tracer.to_a)
  end

  def test_listen_and_doesnt_match

    pdef = Ruote.define do
      concurrence :count => 1 do
        listen :to => 'stone', :upon => 'entering' do
          echo 'stone'
        end
        sequence :tag => 'milestone' do
          echo 'milestone'
        end
      end
    end

    assert_trace "milestone", pdef
  end

  def test_listen_and_do_match

    pdef = Ruote.define do
      concurrence :count => 1 do
        listen :to => /stone/, :upon => 'entering' do
          echo 'stone'
        end
        sequence :tag => 'milestone' do
          echo 'milestone'
        end
      end
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal %w[ milestone stone ], @tracer.to_a
  end

  # somewhere between Haneda and Changi (Thu Apr 21 00:56:19 JST 2011)

  def test_listen_to_errors

    @dashboard.context['ruby_eval_allowed'] = true

    pdef = Ruote.define do
      concurrence :count => 1 do
        listen :to => :errors do
          echo 'error:${f:__error__.message}'
        end
        sequence do
          nemo
        end
      end
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    @dashboard.wait_for(3)
      # give it some time (steps) to launch the listen block

    assert_equal "error:unknown participant or subprocess 'nemo'", @tracer.to_s
  end

  def test_listen_and_caught_errors

    pdef = Ruote.define do
      concurrence :count => 1 do
        listen :to => :errors do
          echo 'error intercepted'
        end
        sequence :on_error => :pass do
          nemo
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal '', @tracer.to_s
  end

  def test_listen_does_not_work_for_errors_in_other_processes

    wfid0 = @dashboard.launch(Ruote.define do
      listen :to => :errors do
        echo 'error intercepted'
      end
    end)

    sleep 0.700

    wfid1 = @dashboard.launch(Ruote.define do
      nemo
    end)

    @dashboard.wait_for(wfid1)

    sleep 0.350
      # just to be sure the 'listen' doesn't trigger

    assert_equal '', @tracer.to_s
  end

  def test_listen_error_class

    pdef = Ruote.define do
      concurrence do
        listen :to => :errors, :class => 'RuntimeError' do
          echo 'runtime error'
        end
        listen :to => :errors, :class => 'ArgumentError' do
          echo 'argument error'
        end
        sequence do
          nemo
        end
        sequence do
          echo '${r:nada}'
        end
      end
    end

    wfid = @dashboard.launch(pdef)

    #sleep 1.000
    4.times { @dashboard.wait_for(wfid) } # error, error, ceased, ceased

    assert_equal(
      true,
      [ "runtime error\nargument error",
        "argument error\nruntime error" ].include?(@tracer.to_s))
  end

  def test_listen_error_message

    @dashboard.context['ruby_eval_allowed'] = true

    pdef = Ruote.define do
      concurrence do
        listen :to => :errors, :msg => /nemo/ do
          echo 'nemo error ${__error__.fei.expid}'
        end
        listen :to => :errors, :msg => 'nada' do
          echo 'nada error ${__error__.fei.expid}'
        end
        sequence do
          nemo
        end
        sequence do
          error 'nada'
        end
      end
    end

    wfid = @dashboard.launch(pdef)

    4.times { @dashboard.wait_for(wfid) } # error, error, ceased, ceased

    assert_equal "nemo error 0_0_2_0\nnada error 0_0_3_0", @tracer.to_s
  end

  def test_listen_error_classes

    pdef = Ruote.define do
      concurrence do
        listen :to => :errors, :class => 'RuntimeError, ArgumentError' do
          echo 'that error ${__error__.fei.expid}'
        end
        sequence do
          nemo
        end
        sequence do
          echo '${r:nada}'
        end
      end
    end

    wfid = @dashboard.launch(pdef)

    #sleep 1.000
    4.times { @dashboard.wait_for(wfid) } # error, error, ceased, ceased

    assert_equal "that error 0_0_1_0\nthat error 0_0_2_0", @tracer.to_s
  end
end

