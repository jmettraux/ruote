
#
# testing ruote
#
# Wed Jul  1 09:51:30 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)
    assert_equal({ 'ref' => 'alpha' }, alpha.first.fields['params'])
    alpha.proceed(alpha.first)

    wait_for(:alpha)
    assert_equal('buy groceries', alpha.first.fields['params']['activity'])
    alpha.proceed(alpha.first)

    wait_for(:alpha)
    assert_equal({ 'ref' => 'alpha' }, alpha.first.fields['params'])
    alpha.proceed(alpha.first)

    wait_for(wfid)
  end

  def test_attribute_text_param

    pdef = Ruote.process_definition do
      alpha 'nemo', :action => 'nada'
      bravo
    end

    @engine.register { catchall }

    #@engine.noisy = true

    @engine.launch(pdef)

    @engine.wait_for(:alpha)
    workitem = @engine.storage_participant.first

    assert_equal(
      { 'nemo' => nil, 'action' => 'nada', 'ref' => 'alpha' }, workitem.params)
    assert_equal(
      'nemo', workitem.param_text)

    @engine.storage_participant.proceed(workitem)

    @engine.wait_for(:bravo)
    workitem = @engine.storage_participant.first

    assert_equal(
      nil, workitem.param_text)
  end
end

