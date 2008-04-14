
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

        li = OpenWFE::LaunchItem.new
        li.attributes.delete "___map_type"
        xml = OpenWFE::Xml.launchitem_to_xml li

        assert_equal(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?><launchitem><workflow_definition_url></workflow_definition_url><attributes><hash></hash></attributes></launchitem>",
            xml)

        li = OpenWFE::Xml.launchitem_from_xml xml

        assert_nil(li.wfdurl)
        assert_equal({}, li.attributes)
    end

    def test_1

        li = OpenWFE::LaunchItem.new
        li.attributes = { "a" => 1, "b" => 2, "c" => [ 1, 2, 3 ]}

        xml = OpenWFE::Xml.launchitem_to_xml li

        assert_equal(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?><launchitem><workflow_definition_url></workflow_definition_url><attributes><hash><entry><string>a</string><number>1</number></entry><entry><string>b</string><number>2</number></entry><entry><string>c</string><array><number>1</number><number>2</number><number>3</number></array></entry></hash></attributes></launchitem>",
            xml)
        
        li = OpenWFE::Xml.launchitem_from_xml xml

        assert_equal({ "a" => 1, "b" => 2, "c" => [ 1, 2, 3 ] }, li.attributes)
    end

    def test_2

        wi = OpenWFE::InFlowWorkItem.new
        wi.fei = new_fei

        xml = OpenWFE::Xml.workitem_to_xml wi

        wi1 = OpenWFE::Xml.workitem_from_xml xml

        assert_equal wi.fei, wi1.fei

        #p wi1.fei
    end

    def test_3

        li = OpenWFE::LaunchItem.new
        li.wfdurl = "http://toto"
        li.customer_name = "toto"

        xml = OpenWFE::Xml.launchitem_to_xml li, 2

        li1 = OpenWFE::Xml.launchitem_from_xml xml

        assert_equal li.wfdurl, li1.wfdurl
        assert_equal li.customer_name, li1.customer_name
    end

end

