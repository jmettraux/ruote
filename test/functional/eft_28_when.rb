
#
# Testing Ruote (OpenWFEru)
#
# Mon Oct 26 17:49:55 JST 2009
#
# in the train from Friboug to Zurich-Flughafen
#

require File.join(File.dirname(__FILE__), 'base')


class EftWhenTest < Test::Unit::TestCase
  include FunctionalBase

  def test_when

    pdef = Ruote.process_definition do
      echo 'in'
      concurrence do
        _when '${v:ok}', :freq => '500' do
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

    assert_trace pdef, %w[ in over done. ]
  end

  def test_when_blocking

    pdef = Ruote.process_definition do
      echo 'in'
      concurrence do
        sequence do
          _when '${v:ok}', :freq => '500'
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

    assert_trace pdef, %w[ in over done. ]
    assert_equal 0, @engine.scheduler.jobs.size
  end

  def test_cancel

    pdef = Ruote.process_definition do
      _when '${v:ok}', :freq => '10d'
      echo 'done.'
    end

    #noisy

    wfid = @engine.launch(pdef)

    sleep 0.500

    assert_equal 1, @engine.scheduler.jobs.size

    @engine.cancel_process(wfid)

    sleep 0.500

    assert_nil @engine.process(wfid)
    assert_equal 0, @engine.scheduler.jobs.size
  end

  def test_when_cron

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

    assert_trace pdef, %w[ in over done. ]

    #Thread.abort_on_exception = true
    #wfid = @engine.launch(pdef)
    #sleep 4
    #Thread.list.each_with_index do |t, i|
    #  puts "#{i} - #{t[:name]} - #{t.inspect}"
    #end
    #assert_equal %w[ in over done. ].join("\n"), @tracer.to_s

    assert_equal 0, @engine.scheduler.jobs.size
  end
end

