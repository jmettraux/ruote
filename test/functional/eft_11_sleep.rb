
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Feb 24 14:39:54 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftSleepTest < Test::Unit::TestCase
  include FunctionalBase

  def test_sleep_for

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence do
          _sleep :for => '1s'
          echo 'a'
        end
        echo 'b'
      end
    end

    assert_trace(pdef, "b\na")
  end

  def test_sleep_for_implicit

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence do
          _sleep '1s'
          echo 'a'
        end
        echo 'b'
      end
    end

    assert_trace(pdef, "b\na")
  end

  def test_sleep_until

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence do
          _sleep :until => "#{Time.now + 1}"
          echo 'a'
        end
        echo 'b'
      end
    end

    assert_trace(pdef, "b\na")
  end

  def test_sleep_scheduler_job

    pdef = OpenWFE.process_definition :name => 'test' do
      _sleep '1h'
    end

    fei = @engine.launch(pdef)

    sleep 0.350

    jobs = @engine.get_scheduler.find_jobs(OpenWFE::WaitExpression.name)

    assert_equal 1, jobs.size

    purge_engine
  end

  def test_sleep_scheduler_job_tags

    pdef = OpenWFE.process_definition :name => 'test' do
      _sleep '1h', :scheduler_tags => 'a, b'
    end

    fei = @engine.launch(pdef)

    sleep 0.350

    assert_equal 1, @engine.get_scheduler.find_jobs('a').size
    assert_equal 1, @engine.get_scheduler.find_jobs('b').size

    purge_engine
  end

end

