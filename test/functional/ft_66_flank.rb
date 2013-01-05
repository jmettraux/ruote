
#
# testing ruote
#
# Tue Aug 30 00:46:07 JST 2011
#
# Santa Barbara
#

require File.expand_path('../base', __FILE__)


class FtFlankTest < Test::Unit::TestCase
  include FunctionalBase

  def test_flank

    pdef = Ruote.process_definition do
      sequence do
        bravo :flank => true
        alpha
      end
    end

    @dashboard.register_participant '.+', Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    ps = @dashboard.ps(wfid)

    assert_equal 4, ps.expressions.size
    assert_equal [ ps.expressions[2].fei.h ], ps.expressions[1].h.flanks

    assert_equal(
      [ ["participant", { "flank" => true, "ref" => "bravo" }, [] ],
        ["participant", { "ref" => "alpha" }, [] ] ],
      ps.leaves.collect(&:tree))
  end

  # Cancelling the sequence also cancels its "flanks".
  #
  def test_cancel

    pdef = Ruote.process_definition do
      sequence do
        bravo :flank => true
        alpha
      end
    end

    @dashboard.register_participant '.+', Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)
    @dashboard.wait_for(1)

    fei = @dashboard.ps(wfid).expressions[1].fei

    @dashboard.cancel(fei)

    @dashboard.wait_for(wfid)
    sleep 1.0

    assert_nil @dashboard.ps(wfid)
  end

  # Expressions replying "naturally" to their parent weren't cancelling their
  # flanks.
  #
  # https://github.com/kennethkalmer/ruote-kit/issues/13
  #
  # This test verifies the fix is in place.
  #
  def test_cancel_flank_when_done

    pdef = Ruote.process_definition do
      sequence do
        sub0 :flank => true
        echo 'over'
      end
      define 'sub0' do
        stall
      end
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(19)

    assert_nil @dashboard.ps(wfid)
  end

  # https://github.com/jmettraux/ruote/issues/47
  #
  def test_cancelling_reminders

    @dashboard.register_participant 'notifier' do |wi|
      tracer << wi.participant_name + "\n"
    end

    @dashboard.register_participant 'form_submitter', Ruote::StorageParticipant

    pdef = Ruote.define do

      form_submitter :timers => '1s: reminder, 2s: cancel_submission'

      define 'reminder' do
        notifier :message_type => 'reminder'
      end

      define 'cancel_submission' do
        notifier :message_type => 'draft_timeout'
        kill_process
      end
    end

    wfid = @dashboard.launch(pdef, 'status' => 'draft')

    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']

    sleep 1

    assert_equal %w[ notifier ] * 2, @tracer.to_a
    assert_equal 0, @dashboard.storage.get_many('expressions').size
    assert_equal 0, @dashboard.storage.get_many('workitems').size
  end

  # for https://groups.google.com/forum/?fromgroups=#!topic/openwferu-users/dZ--leQgEns
  #
  def test_ceasing_flank

    @dashboard.register { catchall }

    pdef =
      Ruote.define do
        sequence :tag => 'x' do
          alice :flank => true
          bob
        end
      end

    wfid = @dashboard.launch(pdef)

    2.times { @dashboard.wait_for('dispatched') }

    alice =
      @dashboard.storage_participant.find { |wi|
        wi.participant_name == 'alice'
      }

    @dashboard.storage_participant.proceed(alice)
    @dashboard.wait_for('receive')

    ps = @dashboard.ps(wfid)

    assert_equal %w[ 0 0_0 0_0_1 ], ps.expressions.collect { |e| e.fei.expid }
    assert_equal 0, ps.errors.size

    bob = @dashboard.storage_participant.first

    @dashboard.storage_participant.proceed(bob)
    @dashboard.wait_for('terminated')

    sleep 0.350

    assert_equal nil, @dashboard.ps(wfid)
  end
end

