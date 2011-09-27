
#
# testing ruote
#
# Wed Jul  1 09:51:30 JST 2009
#

require File.expand_path('../base', __FILE__)


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

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

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

    @dashboard.register { catchall }

    #@dashboard.noisy = true

    @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)
    workitem = @dashboard.storage_participant.first

    assert_equal(
      { 'nemo' => nil, 'action' => 'nada', 'ref' => 'alpha' }, workitem.params)
    assert_equal(
      'nemo', workitem.param_text)

    @dashboard.storage_participant.proceed(workitem)

    @dashboard.wait_for(:bravo)
    workitem = @dashboard.storage_participant.first

    assert_equal(
      nil, workitem.param_text)
  end

  def test_param_or_field

    pdef = Ruote.process_definition do
      alpha
      alpha :theme => :wagner
    end

    @dashboard.register :alpha do |workitem|
      context.tracer << "pof_theme:#{workitem.param_or_field(:theme)}\n"
      context.tracer << "fop_theme:#{workitem.field_or_param(:theme)}\n"
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef, 'theme' => 'mozart')
    @dashboard.wait_for(wfid)

    assert_equal %w[
       pof_theme:mozart fop_theme:mozart
       pof_theme:wagner fop_theme:mozart
    ], @tracer.to_a
  end
end

