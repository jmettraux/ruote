
#
# testing ruote
#
# Mon Oct 26 17:49:55 JST 2009
#
# in the train from Friboug to Zurich-Flughafen
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftOnceTest < Test::Unit::TestCase
  include FunctionalBase

  def test_once

    pdef = Ruote.process_definition do
      echo 'in'
      concurrence do
        once '${v:ok}', :freq => '1s' do
          echo 'done.'
        end
        sequence do
          wait '1s'
          echo 'over'
          set 'v:ok' => true
        end
      end
    end

    #noisy

    assert_trace %w[ in over done. ], pdef

    assert_equal 0, @engine.storage.get_many('schedules').size
  end

  def test_once_blocking

    pdef = Ruote.process_definition do
      echo 'in'
      concurrence do
        sequence do
          once '${v:ok}', :freq => '1s'
          echo 'done.'
        end
        sequence do
          wait '1s'
          echo 'over'
          set 'v:ok' => true
        end
      end
    end

    #noisy

    assert_trace %w[ in over done. ], pdef

    assert_equal 0, @engine.storage.get_many('schedules').size
  end

  def test_cancel

    pdef = Ruote.process_definition do
      once '${v:ok}', :freq => '10d'
      echo 'done.'
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(2)

    assert_equal 1, @engine.storage.get_many('schedules').size

    @engine.cancel_process(wfid)

    wait_for(4)

    assert_nil @engine.process(wfid)
    assert_equal 0, @engine.storage.get_many('schedules').size
  end

  def test_cancel_once_child_is_active

    pdef = Ruote.process_definition do
      as_soon_as 'true', :freq => '10d' do
        alpha
      end
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    @engine.cancel(wfid)

    @engine.wait_for(wfid)

    assert_equal 0, @engine.storage_participant.size
    assert_equal 0, @engine.storage.get_many('schedules').size
  end

  def test_once_cron

    pdef = Ruote.process_definition do
      echo 'in'
      concurrence do
        _when '${v:ok}', :freq => '* * * * * *' do # every second
          echo 'done.'
        end
        sequence do
          wait '1s'
          echo 'over'
          set 'v:ok' => true
        end
      end
    end

    #noisy

    assert_trace %w[ in over done. ], pdef

    assert_equal 0, @engine.storage.get_many('schedules').size
  end
end

