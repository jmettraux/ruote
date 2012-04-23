
#
# testing ruote
#
# Tue Jul 20 12:47:36 JST 2010
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftRefTest < Test::Unit::TestCase
  include FunctionalBase

  class AlphaParticipant
    include Ruote::LocalParticipant

    def consume(workitem)
      @context.tracer << workitem.fei.expid
      @context.tracer << "\n"
      reply(workitem)
    end
  end

  def test_participant

    pdef = Ruote.process_definition do
      ref :ref => 'alpha'
      ref 'alpha'
      echo 'done.'
    end

    @dashboard.register_participant :alpha, AlphaParticipant

    #noisy

    assert_trace %w[ 0_0 0_1 done. ], pdef
  end

  def test_subprocess

    pdef = Ruote.process_definition do

      define 'alpha' do
        echo 'alpha'
      end

      sequence do
        ref :ref => 'alpha'
        ref 'alpha'
        echo 'done.'
      end
    end

    assert_trace %w[ alpha alpha done. ], pdef
  end

  def test_missing_participant_ref

    pdef = Ruote.process_definition do
      ref 'alpha'
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    # correct problem and replay at error

    @dashboard.register_participant 'alpha', AlphaParticipant

    @dashboard.replay_at_error(ps.errors.first)

    @dashboard.wait_for(wfid)

    assert_nil @dashboard.process(wfid)
    assert_equal '0_0', @tracer.to_s
  end

  def test_missing_subprocess_ref

    pdef = Ruote.process_definition do
      ref 'alpha'
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    # correct problem and replay at error

    @dashboard.variables['alpha'] = Ruote.process_definition do
      echo 'alpha'
    end

    @dashboard.replay_at_error(ps.errors.first)

    @dashboard.wait_for(wfid)

    assert_nil @dashboard.process(wfid)
    assert_equal 'alpha', @tracer.to_s
  end

  # Making sure that the ref expression forces the triggered subprocess to
  # consider its timeout.
  #
  def test_ref_and_subprocess_timeout

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      define 'sub0' do
        alpha
      end
      ref 'sub0', :timeout => '2d'
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(:alpha)

    scheds = @dashboard.schedules

    assert_equal 1, scheds.size
    assert_equal '0_1', scheds.first['target'].expid
  end

  def test_missing_ref_and_undo

    pdef = Ruote.process_definition do
      ref 'nemo', :on_error => 'undo'
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_nil @dashboard.process(wfid)
  end

  def test_ref_pointing_to_filter

    @dashboard.variables['needs'] = 'filter'

    pdef = Ruote.process_definition do
      needs { x :type => 'string' }
    end

    wfid = @dashboard.launch(pdef, 'x' => 'nada')
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end
end

