
#
# testing ruote
#
# Mon Oct 24 09:10:41 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtOnTerminateTest < Test::Unit::TestCase
  include FunctionalBase

  def test_regenerate

    # var0 is used to determine if root variables are passed correctly
    # to the next generation of the workflow instance.

    pdef = Ruote.define :on_terminate => :regenerate do
      echo '${wfid}'
      echo '${v:var0}'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef, {}, { 'var0' => 'x' })

    3.times { @dashboard.wait_for('regenerate') }

    assert @tracer.to_a.size >= 3
    assert_equal [ wfid, 'x' ], @tracer.to_a.uniq
    #assert_not_nil @dashboard.ps(wfid)
  end

  def test_cancel_regenerating_flow

    pdef = Ruote.define :on_terminate => :regenerate do
      echo 'a'
      wait 0.100
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    2.times { @dashboard.wait_for('regenerate') }

    @dashboard.cancel(wfid)
    @dashboard.cancel(wfid)

    sleep 3.0

    assert_equal(
      2,
      @dashboard.context.logger.log.select { |m|
        m['action'] == 'regenerate'
      }.size)
  end
end

