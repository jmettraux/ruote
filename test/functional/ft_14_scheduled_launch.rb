
#
# Testing Ruote (OpenWFEru)
#
# jmettraux@gmail.com
#
# Sun May 10 20:55:38 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtScheduledLaunchTest < Test::Unit::TestCase
  include FunctionalBase

  DEF0 = OpenWFE.process_definition do
    echo 'hello'
  end

  def test_launch_in

    @engine.launch(DEF0, :in => '1s')

    sleep 0.450

    assert_equal '', @tracer.to_s

    assert_equal 1, @engine.get_scheduler.all_jobs.size

    sleep 2

    assert_equal 'hello', @tracer.to_s
  end
end
