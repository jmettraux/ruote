
#
# testing ruote
#
# Wed Jul  1 09:51:30 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class FtParticipantParamsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_params

    pdef = Ruote.process_definition do
      sequence do
        alpha
        alpha :activity => 'buy groceries'
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)
    assert_equal({ 'ref' => 'alpha' }, alpha.first.fields['params'])
    alpha.reply(alpha.first)

    wait_for(:alpha)
    assert_equal('buy groceries', alpha.first.fields['params']['activity'])
    alpha.reply(alpha.first)

    wait_for(:alpha)
    assert_equal({ 'ref' => 'alpha' }, alpha.first.fields['params'])
    alpha.reply(alpha.first)

    wait_for(wfid)
  end
end

