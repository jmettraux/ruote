
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Thu Nov 20 14:07:14 JST 2008
#

require 'rubygems'

require 'openwfe/def'

require 'flowtestbase'

require 'openwfe/engine/file_persisted_engine'
require 'openwfe/expool/errorjournal'
require 'openwfe/representations'



class FlowTest58c < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      participant :alpha
      participant :bravo
    end
  end

  #
  # checking to_xml and to_json
  #
  def test_0

    ejournal = @engine.get_error_journal

    @engine.register_participant(:alpha) do |wi|
      raise 'something went wrong Major Tom'
    end

    fei = launch Test0

    sleep 0.350

    ps = @engine.process_status(fei)

    xml = OpenWFE::Xml.process_to_xml(ps, :indent => 2, :linkgen => :plain)
    #puts xml
    xml = REXML::Document.new(xml)

    assert_equal(
      'something went wrong Major Tom', xml.root.elements['//message'].text)

    h = OpenWFE::Json.process_to_h(ps, :linkgen => :plain)
    #puts h.inspect

    errs = h['errors']
    #p h['errors']

    assert_equal 2, errs.size
    assert_equal 1, errs['elements'].size

    assert_equal(
      'something went wrong Major Tom', errs['elements'].first['message'])

    #p ps.all_expressions.collect { |exp| exp.fei.to_s }
    xml = OpenWFE::Xml.expressions_to_xml(
      ps.all_expressions, :indent => 2, :linkgen => :plain)
    #puts xml
    assert_match "<link href=\"/expressions/#{fei.wfid}/0e\" rel=\"environment_expression\"/>", xml

    #
    # checking processes_to_h

    pss = @engine.list_process_status

    a = OpenWFE::Json.processes_to_h(pss, :linkgen => :plain)
    assert_equal 1, a['elements'].size

    purge_engine
  end
end

