
#
# Testing Ruote (OpenWFERu)
#
# John Mettraux at openwfe.org
#
# Sun Apr 13 19:03:31 JST 2008
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/util/xml'


class XmlUtilTest < Test::Unit::TestCase

  def test_0

    a = <<-EOS
<array>
  <string>alpha</string>
  <number>2</number>
  <number>2.3</number>
  <false/>
  <null/>
</array>
    EOS
    a = a.strip

    o = OpenWFE::Xml.from_xml a

    assert_equal [ 'alpha', 2, 2.3, false, nil ], o

    a1 = OpenWFE::Xml.to_xml(o, :indent => 2, :instruct => false).strip

    assert_equal a, a1
  end

  def test_1

    x = <<-EOS
<process>
  <definition><![CDATA[
    <process-definition name="toto">
    </process-definition>
  ]]></definition>
</process>
    EOS

    assert_equal(
      %{<process-definition name="toto">
    </process-definition>},
      OpenWFE::Xml.text(REXML::Document.new(x).root, 'definition').strip)
  end

end

