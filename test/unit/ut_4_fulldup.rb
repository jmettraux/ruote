
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# since Mon Oct  9 22:19:44 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'rexml/document'

require 'openwfe/utils'
require 'openwfe/workitem'


class FullDupTest < Test::Unit::TestCase

  class MyClass

    attr_reader :name

    def initialize (name)
      @name = name
    end
  end

  def test_fulldup_0

    o0 = MyClass.new('cow')

    o1 = OpenWFE.fulldup(o0)

    assert_not_equal o0.object_id, o1.object_id
    assert_equal o0.name, o1.name
  end

  def test_fulldup_1

    a0 = A.new
    a0.a = 1
    a0.b = 2
    a1 = OpenWFE.fulldup(a0)

    #puts a0
    #puts a1

    assert_equal a0, a1
  end

  #def test_yaml
  #  require 'yaml'
  #  o0 = MyClass.new("pig")
  #  o1 = YAML.load(o0.to_yaml)
  #  assert_not_equal o0.object_id, o1.object_id
  #  assert_equal o0.name, o1.name
  #end

  def test_xml_0
    d = REXML::Document.new('<document/>')
    d1 = OpenWFE.fulldup(d)
    assert_not_equal d.object_id, d1.object_id
  end

  def test_xml_1
    d = REXML::Document.new('<document>text</document>')
    d1 = OpenWFE::fulldup(d)
    assert_not_equal d.object_id, d1.object_id
  end

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

  def test_xml_2
    d = REXML::Document.new PAT_XML
    d1 = OpenWFE::fulldup(d)
    assert_not_equal d.object_id, d1.object_id
    assert_equal d.to_s, d1.to_s
  end

  def test_xml_3
    d = REXML::Text.new "toto"
    d1 = OpenWFE::fulldup(d)
    assert d.object_id != d1.object_id
  end

  def test_xml_4
    wi = OpenWFE::InFlowWorkItem.new
    wi.xml_stuff = REXML::Text.new('whatever')
    wi1 = wi.dup
    assert wi.object_id != wi1.object_id
    assert wi.xml_stuff.object_id != wi1.xml_stuff.object_id
    assert_equal wi.xml_stuff, wi1.xml_stuff
  end

  def test_fulldup_2
    require 'date'
    d = DateTime.now
    d1 = OpenWFE::fulldup(d)
    assert_not_equal d.object_id, d1.object_id
    assert_equal d.to_s, d1.to_s
  end

  def test_fulldup_3
    t = Time.new
    sleep 0.100
    t1 = OpenWFE::fulldup(t)
    assert_not_equal t.object_id, t1.object_id
    assert_equal t.to_f, t1.to_f
  end

  def test_fulldup_4
    s = :symbol
    s1 = OpenWFE::fulldup(s)
    assert_equal s.object_id, s1.object_id
    assert_equal s, s1
  end

  def test_fulldup_5
    require 'rational'
    r = Rational(4, 5)
    r1 = OpenWFE.fulldup(r)
    assert_not_equal r.object_id, r1.object_id
    assert_equal r, r1
  end

  private

  class A
    attr_accessor :a, :b

    def == (other)
      return false if not other.kind_of?(A)
      (self.a == other.a and self.b == other.b)
    end

    def to_s
      "A : a='#{a}', b='#{b}'"
    end
  end
end
