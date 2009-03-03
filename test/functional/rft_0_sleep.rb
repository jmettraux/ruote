
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Wed Feb  4 10:10:54 JST 2009
#

require File.dirname(__FILE__) + '/base'
require File.dirname(__FILE__) + '/restart_base'


class RftSleepTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  PDEF0 = OpenWFE.process_definition :name => 'test' do
    sequence do
      echo 'a'
      _sleep '2s'
      echo 'b'
    end
  end

  def test_sleep_restarts_at_wakeup

    in_memory_engine && return

    @engine.launch(PDEF0)

    sleep 1

    @engine.stop

    assert_equal 'a', @tracer.to_s

    sleep 2

    assert_equal 'a', @tracer.to_s

    restart_engine

    sleep 0.350

    assert_equal "a\nb", @tracer.to_s

    assert_engine_clean
  end

  def test_sleep_restarts_after_wakeup

    in_memory_engine && return

    @engine.launch(PDEF0)

    sleep 0.500

    @engine.stop

    assert_equal 'a', @tracer.to_s

    restart_engine

    sleep 0.350

    assert_equal 'a', @tracer.to_s

    sleep 1.500

    assert_equal "a\nb", @tracer.to_s

    assert_engine_clean
  end
end

