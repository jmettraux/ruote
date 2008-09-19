
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Apr 13 19:03:31 JST 2008
#

require 'rubygems'

require 'test/unit'

require 'openwfe/workitem'
require 'openwfe/flowexpressionid'
require 'openwfe/util/xml'

require 'rutest_utils'


class UtilXmlTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

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

end

