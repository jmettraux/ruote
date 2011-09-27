
#
# testing ruote
#
# Tue Oct 27 16:13:41 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftCronTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cron

    pdef = Ruote.process_definition do
      cron '* * * * * *' do
        echo 'ok'
      end
    end

    #noisy

    t = Time.now
    wfid = @dashboard.launch(pdef)

    wait_for(7)

    d = Time.now - t

    @dashboard.cancel_process(wfid)

    wait_for(5)

    assert_match /^ok\nok/, @tracer.to_s
    assert_nil @dashboard.process(wfid)
    assert_equal 0, @dashboard.storage.get_many('schedules').size
    #assert d < 5.0, "#{d} < 5.0 :("
  end

  def test_every

    pdef = Ruote.process_definition do
      every '1s' do
        echo 'ok'
      end
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(7)

    @dashboard.cancel_process(wfid)

    wait_for(5)

    assert_match /^ok\nok/, @tracer.to_s
    assert_nil @dashboard.process(wfid)
    assert_equal 0, @dashboard.storage.get_many('schedules').size
  end
end

