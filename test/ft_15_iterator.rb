
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'rubygems'

require 'openwfe/def'
require 'openwfe/participants/participants'
require 'flowtestbase'


class FlowTest15 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class TestDefinition0 < OpenWFE::ProcessDefinition
        def make
            process_definition :name => "test0", :revision => "0" do
                iterator :on_value => "x, y, z", :to_variable => "v0" do
                    _print "${f:__ip__} -- ${v0}"
                end
            end
        end
    end

    def test_ppd_0

        dotest(
            TestDefinition0,
            [ "0 -- x", "1 -- y", "2 -- z" ].join("\n"))
    end

    #
    # Test 0b
    #

    class Test0b < OpenWFE::ProcessDefinition
        iterator :on_value => "1,2,3", :to_variable => "j" do
            _print "${f:__ip__} -- ${j}"
        end
    end

    def test_0b

        dotest(
            Test0b,
            [ "0 -- 1", "1 -- 2", "2 -- 3" ].join("\n"))
    end

    #
    # Test 0c
    #

    TEST0C = '''
<process-definition name="test" revision="0c">
    <sequence>

        <iterator on-value = "1,2,3" to-variable = "j">
            <print>${f:__ip__} -- ${j}</print>
        </iterator>

        <set field="control" value="1,2,3" />
        <iterator on-value = "${f:control}" to-variable = "j">
            <print>${f:__ip__} -- ${j}</print>
        </iterator>

    </sequence>
</process-definition>
    '''.strip

    def test_0c

        dotest(
            TEST0C,
            """0 -- 1
1 -- 2
2 -- 3
0 -- 1
1 -- 2
2 -- 3""")
    end


    #
    # Test 1
    #

    class TestDefinition1 < OpenWFE::ProcessDefinition
        def make
            process_definition :name => "test1", :revision => "0" do
                iterator :on_value => "x, y, z", :to_field => "f0" do
                    _print "${f:__ip__} -- ${f:f0}"
                end
            end
        end
    end

    def test_ppd_1

        dotest(
            TestDefinition1,
            [ "0 -- x",  "1 -- y", "2 -- z" ].join("\n"))
    end


    #
    # Test 2
    #

    class TestDefinition2 < OpenWFE::ProcessDefinition
        def make
            iterator \
                :on_value => "xayaz", 
                :to_field => "f0",
                :value_separator => "a" do

                _print "${f:__ip__} -- ${f:f0}"
            end
        end
    end

    def test_iterator_2

        dotest(
            TestDefinition2,
            [ "0 -- x", "1 -- y", "2 -- z" ].join("\n"))
    end


    #
    # Test 3
    #

    class TestDefinition3 < OpenWFE::ProcessDefinition
        sequence do
            iterator :on_value => "", :to_field => "f0" do
                _print "${f:__ip__} -- ${f:f0}"
            end
            _print "done."
        end
    end

    def test_iterator_3

        dotest TestDefinition3, "done."
    end


    #
    # Test 4
    #

    class TestDefinition4 < OpenWFE::ProcessDefinition
        sequence do
            iterator :on_value => "a, b, c", :to_field => "f0" do
                sequence do
                    _print "${f:__ip__} -- ${f:f0}"
                    _break :if => "${f:__ip__} == 1"
                end
            end
            _print "done."
        end
    end

    def test_iterator_4

        dotest TestDefinition4, "0 -- a\n1 -- b\ndone."
    end


    #
    # Test 5
    #

    class TestDefinition5 < OpenWFE::ProcessDefinition
        sequence do
            iterator :on_value => "a, b, c, d, e, f, g", :to_field => "f0" do
                sequence do
                    _print "${f:__ip__} -- ${f:f0}"
                    skip 2, :if => "${f:__ip__} == 1"
                end
            end
            _print "done."
        end
    end

    def test_iterator_5

        dotest(
            TestDefinition5, 
            """
0 -- a
1 -- b
4 -- e
5 -- f
6 -- g
done.
            """.strip)
    end

end

