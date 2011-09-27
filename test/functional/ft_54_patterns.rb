
#
# testing ruote
#
# Fri Jan  7 15:13:28 JST 2011
#

require File.expand_path('../base', __FILE__)

#require 'ruote/participant'


class FtPatternsTest < Test::Unit::TestCase
  include FunctionalBase


  # A task is only enabled when the process instance (of which it is part) is
  # in a specific state (typically a parallel branch). The state is assumed to
  # be a specific execution point (also known as a milestone) in the process
  # model. When this execution point is reached the nominated task can be
  # enabled. If the process instance has progressed beyond this state, then the
  # task cannot be enabled now or at any future time (i.e. the deadline has
  # expired). Note that the execution does not influence the state itself, i.e.
  # unlike normal control-flow dependencies it is a test rather than a trigger.

  #MILESTONE = Ruote.define do
  #
  #  concurrence :count => 1 do
  #
  #    sequence do
  #      participant 'a'
  #      participant 'b', :tag => 'milestone'
  #      participant 'c'
  #    end
  #
  #    listen :to => 'milestone', :upon => 'entering', :wfid => true do
  #      concurrence :count => 1 do
  #        listen :to => 'milestone', :upon => 'leaving', :wfid => true
  #        participant 'd'
  #      end
  #    end
  #  end
  #end
    # this works, but, if the participant d implementation is 'fast', the
    # milestone could be left before the inner listen is reached.
    # This listen could thus listen for an event that already occurred and
    # thus be locked...
    #
    # the revised version makes sure the milestone is listened to (bot#
    # entering and leaving) before participant b is reached.

  MILESTONE = Ruote.define do

    concurrence do

      sequence do
        participant 'a'
        participant 'b', :tag => 'milestone'
        participant 'c'
      end

      concurrence :count => 1 do
        sequence do
          listen :to => 'milestone', :upon => 'entering', :wfid => true
          participant 'd'
        end
        listen :to => 'milestone', :upon => 'leaving', :wfid => true
      end
    end
  end

  def test_18_milestone

    @dashboard.register do
      catchall Ruote::StorageParticipant
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(MILESTONE)

    @dashboard.wait_for(:a)

    assert_equal({}, @dashboard.ps(wfid).tags)

    @dashboard.storage_participant.proceed(@dashboard.storage_participant.first)

    @dashboard.wait_for(:d)

    assert_equal %w[ milestone ], @dashboard.ps(wfid).tags.collect { |t| t.first }
    assert_equal %w[ b d ], @dashboard.ps(wfid).position.collect { |pos| pos[1] }

    wi = @dashboard.storage_participant.by_participant('b').first
    @dashboard.storage_participant.proceed(wi)

    @dashboard.wait_for(:c)

    @dashboard.wait_for('dispatch_cancel')
    @dashboard.wait_for(1)
      # give some time for the task d to get removed

    assert_equal({}, @dashboard.ps(wfid).tags)
    assert_equal %w[ c ], @dashboard.ps(wfid).position.collect { |pos| pos[1] }
  end
end

