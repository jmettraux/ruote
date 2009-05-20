
#
# Testing Ruote (OpenWFEru)
#
# Sat Jan 24 22:40:35 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/null_participant'


class EftProcessDefinitionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_procdef

    assert_trace(
      Ruote.define(:name => 'test_1') { },
      '')
  end

  def test_sub_definition

    pdef = Ruote.process_definition :name => 'main' do
      define :name => 'sub0' do
      end
      participant :ref => :null
    end

    @engine.register_participant :null, Ruote::NullParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait

    ps = @engine.process_status(wfid)

    assert_equal({"sub0"=>["sequence", {"name"=>"sub0"}, []]}, ps.variables)
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

