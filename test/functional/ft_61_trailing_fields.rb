
#
# testing ruote
#
# Thu Jun  9 11:37:56 JST 2011
#

require File.join(File.dirname(__FILE__), 'base')


class FtTrailingFields < Test::Unit::TestCase
  include FunctionalBase

  def test_t_fields

    pdef = Ruote.define do
      alpha
      echo 'a', :if => '${t.verbose}'
      bravo
      echo 'b', :if => '${t.verbose}'
    end

    @engine.register(:alpha) { |wi| wi.t['verbose'] = true }
    @engine.register(:bravo, Ruote::NoOpParticipant)

    #@engine.noisy = true

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal 'a', @tracer.to_s
  end
end

