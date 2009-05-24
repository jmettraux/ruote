
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/util/json'

require 'openwfe/util/json'
#require 'openwfe/workitem'
#require 'openwfe/rudefinitions'
#require 'openwfe/flowexpressionid'
require 'openwfe/representations'


class RepresentationsHashTest < Test::Unit::TestCase

  def test_fei_to_h

    fei0 = new_fei
    h = fei0.to_h
    fei1 = OpenWFE::FlowExpressionId.from_h(h)

    assert_equal fei0, fei1
  end

  def test_wi_to_h

    wi0 = OpenWFE::InFlowWorkItem.new
    wi0.fei = new_fei

    h = wi0.to_h
    #p h

    wi1 = OpenWFE::InFlowWorkItem.from_h(h)

    assert_equal wi0.fei, wi1.fei
    assert_equal wi0.attributes.length, wi1.attributes.length

    wi2 = OpenWFE::workitem_from_h(h)

    assert_equal wi0.fei, wi2.fei
    assert_equal wi0.attributes.length, wi2.attributes.length
  end

  def test_wi_to_h_and_links

    wi0 = OpenWFE::InFlowWorkItem.new
    wi0.fei = new_fei
    wi0.car = 'prius'
    wi0.count = 2

    h = OpenWFE::Json.workitem_to_h(wi0, :linkgen => :plain)
    assert_equal 2, h['links'].size
    #puts h.to_json
  end

  def test_any_from_h

    li = OpenWFE::LaunchItem.new
    li.workflow_definition_url = 'http://www.openwfe.org/nada'
    li.price = 'USD 12'
    li.customer = 'Captain Nemo'

    h = li.to_h
    #p h

    li1 = OpenWFE::workitem_from_h h

    assert_kind_of OpenWFE::LaunchItem, li1
    assert_equal 'USD 12', li1.price
    assert_equal 2, li1.attributes.size
  end

  def test_wi_to_h_to_json_and_back

    wi0 = OpenWFE::InFlowWorkItem.new
    wi0.fei = new_fei
    wi0.attributes['data'] = (0..5).to_a

    s = OpenWFE::Json.encode( wi0.to_h )
    #puts s

    #wi1 = OpenWFE::InFlowWorkItem.from_h(JSON.parse(s))
    wi1 = OpenWFE::InFlowWorkItem.from_h(OpenWFE::Json.from_json(s))

    assert_equal wi0.attributes, wi1.attributes
    assert_equal wi0.fei, wi1.fei
  end

end

