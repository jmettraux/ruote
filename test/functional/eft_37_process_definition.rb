
#
# testing ruote
#
# Sat Jan 24 22:40:35 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftProcessDefinitionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_procdef

    assert_trace(
      '',
      Ruote.define(:name => 'test_1') { })
  end

  def test_sub_definition

    pdef = Ruote.process_definition :name => 'main' do
      define :name => 'sub0' do
      end
      participant :ref => :alpha
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert_equal(
      {"sub0"=> ["0_0", ["define", {"name"=>"sub0"}, []]],
       "main"=> ["0", ["define", {"name"=>"main"}, [["define", {"name"=>"sub0"}, []], ["participant", {"ref"=>"alpha"}, []]]]]},
      ps.variables)
  end

  #def test_define_implicit_name
  #  pdef = Ruote.define 'accounting_process' do
  #  end
  #  assert_equal 'accounting_process', pdef[1]['name']
  #end

  def test_sub_define_implicit_name

    pdef = Ruote.define 'accounting_process' do
      define 'sub0' do
      end
    end

    assert_equal(
      ["define", {"accounting_process"=>nil}, [["define", {"sub0"=>nil}, []]]],
      pdef)
  end
end

