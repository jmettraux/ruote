
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Aug  3 12:13:11 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class EftSaveTest < Test::Unit::TestCase
  include FunctionalBase

  def test_save_to_variable

    pdef = Ruote.process_definition :name => 'test' do
      save :to_variable => 'v'
      alpha
    end

    #noisy

    @engine.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal Ruote::Workitem, ps.variables['v'].class
  end

  def test_save_to_field

    pdef = Ruote.process_definition :name => 'test' do
      set :field => 'nada', :value => 'surf'
      save :to_f => 'f'
      alpha
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 'surf', alpha.first.fields['f']['nada']
  end
end

