
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

  def test_sleep_restart

    in_memory_engine && return

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        _print 'a'
        _sleep '2s'
        _print 'b'
      end
    end

    @engine.launch(pdef)

    sleep 1

    @engine.stop

    assert_equal 'a', @tracer.to_s

    sleep 2

    assert_equal 'a', @tracer.to_s

    restart_engine

    sleep 0.100

    assert_equal "a\nb", @tracer.to_s

    check_engine_clean
  end

  def test_sleep_restart_b

    in_memory_engine && return

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        _print 'a'
        _sleep '2s'
        _print 'b'
      end
    end

    @engine.launch(pdef)

    sleep 0.500

    @engine.stop

    assert_equal 'a', @tracer.to_s

    restart_engine

    sleep 0.350

    assert_equal 'a', @tracer.to_s

    sleep 1.500

    assert_equal "a\nb", @tracer.to_s

    check_engine_clean
  end
end

