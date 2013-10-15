
#
# testing ruote
#
# Sat Oct  5 23:42:53 CEST 2013
#
# By Marcello Barnaba @vjt
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class CtHeavyConcurrence < Test::Unit::TestCase
  include FunctionalBase

  class FooParticipant < Ruote::StorageParticipant
  end

  def test_cancel_concurrence

    n = 10

    pdef = Ruote.process_definition do
      #sequence do
        concurrence do
          n.times do |i|
            #tag = "t#{i}"
            #repeat :tag => tag do
            #  foo
            #  stop :ref => tag
            #end
            #repeat do
            #  foo
            #  stop
            #end
            foo
          end
        end
      #end
    end

    @dashboard.register_participant :foo, FooParticipant
    @dashboard.noisy = (ENV['NOISY'] == 'true')

    # A worker process is required in order to reproduce the issue.
    # If this test is run just on the @dashboard, it works perfectly.
    #
    # I've noticed that in the worker process the actions are logged
    # interleaved, so they run concurrently. This is the root cause
    # of the issue.
    fork {
      worker = Ruote::Worker.new(determine_storage({}))
      dboard = Ruote::Dashboard.new(worker)
      dboard.noisy = (ENV['NOISY'] == 'true')
      class << worker
        def handle_step_error
          #puts "=========== aborting!!!"
          abort # To avoid infinite loops
        end
      end
      worker.join
    }

    wfid = @dashboard.launch(pdef)

    # With the memory storage, the wait_for works as expected.
    # But, with fsstorage or couch storage, it yields only some
    # of the messages, thus never completing.
    #sleep 5
    ##Array.new(n).map { wait_for('dispatched', 10) }
    #wis = @dashboard.storage.get_many('workitems')
    #assert_equal n, wis.size

    loop do
      s = @dashboard.storage.get_many('workitems').size
      break if s == n
      sleep 0.1
    end
      #
      # this work with dispatch happening in this or the forked worker

    # The cancel triggers the bug
    @dashboard.cancel_process(wfid)

    #wait_for(wfid)
      #
      # that doesn't work if the process is terminated
      # in the forked worker
      #
    count = 0
    loop do

      ps = @dashboard.process(wfid)

      break if ps == nil # success, process has terminated

      ps.expressions.each do |exp|
        p [ exp.class, exp.fei.sid, exp.state ]
        if exp.is_a?(Ruote::Exp::ConcurrenceExpression)
          p [ :expecting, exp.h.children.collect { |i| i['expid'] } ]
        end
      end if count > 34

      sleep 0.1

      count += 1

      assert_equal(true, false, '/!\ process is stuck /!\ ') if count > 35
    end

    assert_equal true, true
  end

  # ありがとうございます。:-)
  #
  #  - @vjt

end

