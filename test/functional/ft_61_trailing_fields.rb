
#
# testing ruote
#
# Thu Jun  9 11:37:56 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtTrailingFields < Test::Unit::TestCase
  include FunctionalBase

  def test_t_fields

    pdef = Ruote.define do
      alpha
      echo 'a', :if => '${t.verbose}'
      bravo
      echo 'b', :if => '${t.verbose}'
    end

    @dashboard.register(:alpha) { |wi| wi.t['verbose'] = true }
    @dashboard.register(:bravo, Ruote::NoOpParticipant)

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'a', @tracer.to_s
  end
end

