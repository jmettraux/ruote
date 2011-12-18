
#
# testing ruote
#
# Mon Aug  3 12:13:11 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftSaveTest < Test::Unit::TestCase
  include FunctionalBase

  def test_save_to_variable

    pdef = Ruote.process_definition :name => 'test' do
      save :to_variable => 'v'
      alpha
    end

    #noisy

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert ps.variables['v'].kind_of?(Hash)
  end

  def test_save_to_field

    pdef = Ruote.process_definition :name => 'test' do
      set :field => 'nada', :value => 'surf'
      save :to_f => 'f'
      alpha
    end

    #noisy

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal 'surf', alpha.first.fields['f']['nada']
  end

  def test_save_to_field_deep

    pdef = Ruote.process_definition :name => 'test' do
      set :field => 'nada', :value => 'surf'
      set :field => 'h', :value => {}
      save :to_f => 'h.wi_as_before'
      alpha
    end

    #noisy

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    #p alpha.first.fields
    assert_equal 'surf', alpha.first.fields['h']['wi_as_before']['nada']
  end

  # sfo -> fra

  def test_save_to_f # and deep f

    pdef = Ruote.process_definition do
      set 'f:x' => 'val0'
      set 'f:h' => {}
      save :to => 'f:h.deep'
      save :to => 'f:a'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    fields = @dashboard.wait_for(wfid)['workitem']['fields']
    Ruote.delete_all(fields, '__result__')

    assert_equal(
      { 'deep' => { 'x' => 'val0', 'h' => {} } },
      fields['h'])
    assert_equal(
      { 'x' => 'val0', 'h' => { 'deep' => { 'x' => 'val0', 'h' => { }  } } },
      fields['a'])
  end

  def test_save_to_v

    pdef = Ruote.process_definition do
      set 'f:x' => 'val0'
      save :to => 'v:a'
      set 'f:y' => '$v:a'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    fields = @dashboard.wait_for(wfid)['workitem']['fields']

    assert_equal({ 'x' => 'val0', '__result__' => 'val0' }, fields['y'])
  end
end

