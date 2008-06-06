
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
# Pat at geobliki.com
#

require 'flowtestbase'
require 'openwfe/def'
require 'openwfe/orest/xmlcodec'
require 'rutest_utils'


class FlowTest50 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # A Test by Pat Cappelaere
  #

  PAT_XML = <<END
<?xml version="1.0" encoding="UTF-8"?>
<sps:GetFeasibilityRequestResponse xmlns:gml="http://www.opengis.net/gml"
xmlns:sps="http://www.opengis.net/sps" xmlns="">
  <sps:Feasibility status="feasible" id="106">
  <DOY>106</DOY>
  <UTC>2007-04-16 09:20:00</UTC>
  <SZA>27.41</SZA>
  <TYPE>NADIR</TYPE>
  <PATH>52</PATH>
  <ROW>186</ROW>
  <COST>2600.85</COST>
  <![CDATA[
    <blah/>boum
  ]]>
  <sps:LatestResponseTime>
    <gml:TimeInstant>
    <gml:timePosition>2007-04-16T09:20:00Z</gml:timePosition>
    </gml:TimeInstant>
  </sps:LatestResponseTime>
  </sps:Feasibility>
</sps:GetFeasibilityRequestResponse>
END

  class TestXmlAttribute50a0 < OpenWFE::ProcessDefinition
    sequence do
      geo_0
      geo_1
    end
  end

  def test_0

    doc0 = nil
    doc1 = nil

    @engine.register_participant :geo_0 do |fei, workitem|
      doc0 = REXML::Document.new(PAT_XML)
      workitem.attributes['xml'] = doc0
      @tracer << "0\n"
    end

    @engine.register_participant :geo_1 do |fei, workitem|
      doc1 = workitem.attributes['xml']
      @tracer << "1\n"
    end

    dotest(TestXmlAttribute50a0, "0\n1")

    assert_equal doc0.to_s, doc1.to_s
  end

  def test_1

    doc0 = REXML::Document.new PAT_XML
    doc1 = OpenWFE::fulldup(doc0)

    assert_not_equal doc0.object_id, doc1.object_id

    assert_equal doc0.to_s, doc1.to_s
  end

  #
  # Against bug #10150
  #
  #def test_2
  #  workitem = OpenWFE::InFlowWorkItem.new
  #  workitem.fei = new_fei
  #  workitem.result = REXML::Document.new PAT_XML
  #  s = OpenWFE::XmlCodec::encode workitem
  #  #puts s
  #  w = OpenWFE::XmlCodec::decode s
  #  w.attributes.delete '___map_type'
  #  #puts workitem.to_s
  #  #puts
  #  #puts w.to_s
  #  assert_equal workitem.to_s, w.to_s
  #end

  def test_3

    workitem = OpenWFE::InFlowWorkItem.new
    workitem.fei = new_fei

    workitem.result = REXML::Document.new(
      PAT_XML, :compress_whitespace=>:all, :ignore_whitespace_nodes=>:all)

    workitem.result = workitem.result.root

    s = OpenWFE::XmlCodec::encode workitem

    #puts s

    w = OpenWFE::XmlCodec::decode s
    w.attributes.delete '___map_type'

    workitem.attributes.delete '___map_type'

    #puts workitem.to_s
    #puts
    #puts w.to_s

    assert_equal workitem.to_s, w.to_s
  end

   def test_4

    doc0 = nil
    doc1 = nil

    @engine.register_participant :geo_0 do |fei, workitem|
      doc0 = REXML::Document.new(PAT_XML).root
      workitem.attributes['xml'] = doc0
      @tracer << "0\n"
    end

    @engine.register_participant :geo_1 do |fei, workitem|
      doc1 = workitem.attributes['xml']
      @tracer << "1\n"
    end

    dotest(TestXmlAttribute50a0, "0\n1")

    assert_equal doc0.to_s, doc1.to_s
   end

end

