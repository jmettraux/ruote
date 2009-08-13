
#
# Testing Ruote (OpenWFEru)
#
# Wed Aug 12 23:24:16 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtListenerRegistrationTest < Test::Unit::TestCase
  include FunctionalBase

  class MyListener
    include Ruote::EngineContext

    def initialize (opts)
    end

    #def pass (workitem)
    #  engine.reply(workitem)
    #end
  end

  def test_register_listener

    #noisy

    listener = @engine.register_listener(MyListener)

    assert_equal MyListener, listener.class
    assert_equal true, listener.listener?
    assert_not_nil listener.context

    assert_equal 1, @engine.listeners.size

    sleep 0.001
    entry = logger.log.last

    assert_equal :listeners, entry[0]
    assert_equal :registered, entry[1]
    assert_not_nil entry[2][:name]
    assert_equal listener, entry[2][:listener]

    @engine.unregister_listener(listener)

    assert_equal 0, @engine.listeners.size

    sleep 0.001
    entry = logger.log.last

    assert_equal :listeners, entry[0]
    assert_equal :unregistered, entry[1]
  end

  class MyScheduledListener
    include Ruote::EngineContext

    def initialize (opts)
    end

    def call (rufus_scheduler_job)
      wqueue.emit(:nada, :nada, {})
    end
  end

  def test_frequency

    listener = @engine.register_listener(MyScheduledListener, :freq => '500')
      # 500 ms

    sleep 2

    assert_equal 1, @engine.scheduler.jobs.size

    nadas = logger.log.select { |e| e[0] == :nada }

    assert nadas.size > 1

    @engine.unregister_listener(listener)

    assert_equal 0, @engine.scheduler.jobs.size
  end
end

