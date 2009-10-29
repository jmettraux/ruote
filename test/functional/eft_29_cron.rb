
#
# Testing Ruote (OpenWFEru)
#
# Tue Oct 27 16:13:41 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class EftCronTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cron

    pdef = Ruote.process_definition do
      cron '* * * * * *' do
        echo 'ok'
      end
    end

    #noisy

    wfid = @engine.launch(pdef)

    sleep 4

    @engine.cancel_process(wfid)

    sleep 0.400

    assert_match /^ok\nok/, @tracer.to_s
    assert_nil @engine.process(wfid)
    assert_equal 0, @engine.scheduler.jobs.size
  end

  def test_every

    pdef = Ruote.process_definition do
      every '200' do
        echo 'ok'
      end
    end

    #noisy

    wfid = @engine.launch(pdef)

    sleep 1

    @engine.cancel_process(wfid)

    sleep 0.400

    assert_match /^ok\nok/, @tracer.to_s
    assert_nil @engine.process(wfid)
    assert_equal 0, @engine.scheduler.jobs.size
  end
end

