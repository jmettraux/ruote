
#
# Testing Ruote (OpenWFEru)
#
# jmettraux@gmail.com
#
# Fri May  8 11:30:25 JST 2009
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/util/json'

require 'openwfe/util/json'
require 'openwfe/representations'


class ErrorRepresentationsTest < Test::Unit::TestCase

  def test_errors_from_xml

    xml = %{<?xml version="1.0" encoding="UTF-8"?>
<errors count="1">
  <link href="/" rel="via"/>
  <link href="/errors" rel="self"/>
  <error>
    <link href="/errors" rel="via"/>
    <link href="/errors/20090508-binohiduwa/0_0" rel="self"/>
    <date>Fri May 08 10:41:53 +0900 2009</date>
    <fei>(fei 0.9.21 ruote_rest field:__definition st_errors t1 20090508-binohiduwa participant 0.0)</fei>
    <call>apply</call>
    <message>pexp : no participant named "tonto"</message>
    <wfid>20090508-binohiduwa</wfid>
    <expid>0.0</expid>
    <workitem>
      <flow_expression_id>
        <owfe_version>0.9.21</owfe_version>
        <engine_id>ruote_rest</engine_id>
        <workflow_definition_url>field:__definition</workflow_definition_url>
        <workflow_definition_name>st_errors</workflow_definition_name>
        <workflow_definition_revision>t1</workflow_definition_revision>
        <workflow_instance_id>20090508-binohiduwa</workflow_instance_id>
        <expression_name>participant</expression_name>
        <expression_id>0.0</expression_id>
        <fei_short>(fei 0.9.21 ruote_rest field:__definition st_errors t1 20090508-binohiduwa participant 0.0)</fei_short>
      </flow_expression_id>
      <last_modified></last_modified>
      <participant_name></participant_name>
      <dispatch_time></dispatch_time>
      <store></store>
      <attributes>
        <hash>
        </hash>
      </attributes>
    </workitem>
  </error>
</errors>
    }

    errors = OpenWFE::Xml.errors_from_xml(xml)

    assert_equal 1, errors.size
    assert_equal 'pexp : no participant named "tonto"', errors.first.stacktrace
    assert_equal({}, errors.first.workitem.attributes)
  end

  def test_errors_from_json

    json = %{
{"elements": [{"message": "Houston,
 we have a problem",
 "wfid": "20090428-begizunobu",
 "date": "2009/05/07 19:22:08 +0900",
 "workitem": {"last_modified": null,
 "type": "OpenWFE::InFlowWorkItem",
 "participant_name": "houston",
 "attributes": {"key1": "value1",
 "params": {"ref": "houston"},
 "key0": "value0"},
 "dispatch_time": "2009/05/07 19:22:08 +0900",
 "flow_expression_id": {"expression_name": "participant",
 "workflow_definition_name": "Test",
 "workflow_definition_revision": "0",
 "expression_id": "0.0.0",
 "workflow_instance_id": "20090428-begizunobu",
 "owfe_version": "0.9.21",
 "engine_id": "ruote_rest",
 "workflow_definition_url": "field:__definition"}},
 "expid": "0.0.0",
 "links": [{"href": "http://localhost:4567/errors",
 "rel": "via"},
 {"href": "http://localhost:4567/errors/20090428-begizunobu/0_0_0",
 "rel": "self"}],
 "fei": "(fei 0.9.21 ruote_rest field:__definition Test 0 20090428-begizunobu participant 0.0.0)"}],
 "links": [{"href": "http://localhost:4567/",
 "rel": "via"},
 {"href": "http://localhost:4567/errors",
 "rel": "self"}]}
    }.gsub(/\n/, '')

    h = OpenWFE::Json.from_json(json)
    errors = OpenWFE::Json.errors_from_h(h)

    assert_equal 1, errors.size
    assert_equal '20090428-begizunobu', errors.first.fei.wfid
  end

  def test_error_from_json

    json = %{
{"message": "Houston,
 we have a problem",
 "wfid": "20090428-begizunobu",
 "date": "2009/05/07 19:22:08 +0900",
 "workitem": {"last_modified": null,
 "type": "OpenWFE::InFlowWorkItem",
 "participant_name": "houston",
 "attributes": {"key1": "value1",
 "params": {"ref": "houston"},
 "key0": "value0"},
 "dispatch_time": "2009/05/07 19:22:08 +0900",
 "flow_expression_id": {"expression_name": "participant",
 "workflow_definition_name": "Test",
 "workflow_definition_revision": "0",
 "expression_id": "0.0.0",
 "workflow_instance_id": "20090428-begizunobu",
 "owfe_version": "0.9.21",
 "engine_id": "ruote_rest",
 "workflow_definition_url": "field:__definition"}},
 "expid": "0.0.0",
 "links": [{"href": "http://localhost:4567/errors",
 "rel": "via"},
 {"href": "http://localhost:4567/errors/20090428-begizunobu/0_0_0",
 "rel": "self"}],
 "fei": "(fei 0.9.21 ruote_rest field:__definition Test 0 20090428-begizunobu participant 0.0.0)"}
    }.gsub(/\n/, '')

    h = OpenWFE::Json.from_json(json)
    error = OpenWFE::Json.error_from_h(h)

    #p error
    assert_equal '20090428-begizunobu', error.fei.wfid
    assert_equal 'value1', error.workitem.attributes['key1']
  end

  def test_error_to_xml

    pe = OpenWFE::ProcessError.new
    pe.fei = new_fei
    pe.date = Time.now
    pe.fdate = pe.date.to_f
    pe.message = 'apply'
    pe.stacktrace = 'nada'

    pe.workitem = OpenWFE::InFlowWorkItem.new
    pe.workitem.fei = pe.fei

    xml = OpenWFE::Xml.error_to_xml(pe, :indent => 2, :linkgen => :plain)
    #puts xml

    #d = pe.date.strftime("%Y%m%d%H%M%S")
    #assert_match /"\/errors\/20080919-equestris\/0_0\/#{d}"/, xml

    assert_match /"\/errors\/20080919-equestris\/0_0"/, xml
    assert_match />#{pe.fdate}</, xml
  end

end

