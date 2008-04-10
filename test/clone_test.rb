
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'test/unit'
require 'rexml/document'

require 'openwfe/utils'
require 'openwfe/workitem'


class FullDupTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    class MyClass

        attr_reader :name

        def initialize (name)
            @name = name
        end
    end

    def test_fulldup

        o0 = MyClass.new("cow")

        o1 = OpenWFE.fulldup(o0)

        assert_not_equal o0.object_id, o1.object_id
        assert_equal o0.name, o1.name
    end

    def test_yaml

        require 'yaml'

        o0 = MyClass.new("pig")
        o1 = YAML.load(o0.to_yaml)

        assert_not_equal o0.object_id, o1.object_id
        assert_equal o0.name, o1.name
    end

    def test_dup_0
        a0 = A.new
        a0.a = 1
        a0.b = 2
        a1 = OpenWFE::fulldup(a0)

        #puts a0
        #puts a1
        
        assert_equal a0, a1, "dup() utility not working"
    end

    def test_dup_1
        d = REXML::Document.new("<document/>")
        d1 = OpenWFE::fulldup(d)
        assert d.object_id != d1.object_id
    end

    def test_dup_2
        d = REXML::Document.new("<document>text</document>")
        d1 = OpenWFE::fulldup(d)
        assert d.object_id != d1.object_id
    end

    def test_dup_3
        d = REXML::Text.new "toto"
        d1 = OpenWFE::fulldup(d)
        assert d.object_id != d1.object_id
    end

    def test_dup_4
        wi = OpenWFE::InFlowWorkItem.new
        wi.xml_stuff = REXML::Text.new "whatever"
        wi1 = wi.dup
        assert wi.object_id != wi1.object_id
        assert wi.xml_stuff.object_id != wi1.xml_stuff.object_id
        assert_equal wi.xml_stuff, wi1.xml_stuff
    end

    def test_dup_5
        require 'date'
        d = DateTime.now
        d1 = OpenWFE::fulldup(d)
        assert_not_equal d.object_id, d1.object_id
        assert_equal d.to_s, d1.to_s
    end

    def test_dup_6
        t = Time.new
        sleep 0.100
        t1 = OpenWFE::fulldup(t)
        assert_not_equal t.object_id, t1.object_id
        assert_equal t.to_f, t1.to_f
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
