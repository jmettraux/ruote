
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#

require 'test/unit'

require 'openwfe/filterdef'


class FilterTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    def test_filter_in

        f0 = OpenWFE::FilterDefinition.new
        f0.closed = true
        f0.add_field("a", "r")
        f0.add_field("b", "rw")
        f0.add_field("c", "")

        m0 = {
            "a" => "A",
            "b" => "B",
            "c" => "C",
            "d" => "D",
        }

        m1 = f0.filter_in m0

        #require 'pp'; pp m0
        #require 'pp'; pp m1
        assert_equal m1, { "a" => "A", "b" => "B" }

        f0.closed = false

        m2 = f0.filter_in m0

        #require 'pp'; pp m0
        #require 'pp'; pp m2
        assert_equal m2, { "a" => "A", "b" => "B", "d" => "D" }
    end

    def test_filter_out_0

        f0 = OpenWFE::FilterDefinition.new
        f0.closed = false
        f0.add_ok = true
        f0.remove_ok = true
        f0.add_field("a", "r")
        f0.add_field("b", "rw")
        f0.add_field("c", "")

        m0 = {
            "a" => "A",
            "b" => "B",
            "c" => "C",
            "d" => "D",
        }

        #
        # 0

        m1 = {
            "z" => "Z"
        }

        m2 = f0.filter_out m0, m1

        #require 'pp'; pp m2
        assert_equal m2, {"z"=>"Z"}

        #
        # 1

        f0.remove_ok = false

        m2 = f0.filter_out m0, m1

        #require 'pp'; pp m2
        assert_equal m2, {"a"=>"A", "b"=>"B", "c"=>"C", "z"=>"Z", "d"=>"D"}

        #
        # 2

        f0.remove_allowed = true

        m1 = {
            "a" => 0,
            "b" => 1,
            "c" => 2,
            "d" => 3
        }

        m2 = f0.filter_out m0, m1

        #require 'pp'; pp m2
        assert_equal m2, {"a"=>"A", "b"=>1, "c"=>"C", "d"=>3}
    end

end

