
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

    @engine.register_participant :alpha, Ruote::StorageParticipant

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal Hash, ps.variables['v'].class
  end

  def test_save_to_field

    pdef = Ruote.process_definition :name => 'test' do
      set :field => 'nada', :value => 'surf'
      save :to_f => 'f'
      alpha
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    wfid = @engine.launch(pdef)

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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    wfid = @engine.launch(pdef)

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

    #@engine.noisy = true

    wfid = @engine.launch(pdef)
    fields = @engine.wait_for(wfid)['workitem']['fields']

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

    #@engine.noisy = true

    wfid = @engine.launch(pdef)
    fields = @engine.wait_for(wfid)['workitem']['fields']

    assert_equal({ 'x' => 'val0' }, fields['y'])
  end
end

