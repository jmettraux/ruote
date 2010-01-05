
#
# testing ruote
#
# Mon Aug  3 12:13:11 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class EftSaveTest < Test::Unit::TestCase
  include FunctionalBase

  def test_save_to_variable

    pdef = Ruote.process_definition :name => 'test' do
      save :to_variable => 'v'
      alpha
    end

    #noisy

    @engine.register_participant :alpha, Ruote::HashParticipant.new

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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    #p alpha.first.fields
    assert_equal 'surf', alpha.first.fields['h']['wi_as_before']['nada']
  end
end

