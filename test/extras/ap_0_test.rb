
require 'test/unit'

require 'extras/ap_test_base'

#require 'openwfe/workitem'
require 'openwfe/extras/participants/activeparticipants'
require 'test/rutest_utils'


class Active0Test < Test::Unit::TestCase
    include ApTestBase

    def setup
        #OpenWFE::Extras::Workitem.delete_all
        #OpenWFE::Extras::Field.delete_all
        OpenWFE::Extras::Workitem.destroy_all
            # let's make sure there are no workitems left
    end

    def teardown
        OpenWFE::Extras::Workitem.destroy_all
    end
    
    #
    # tests

    def test_0

        wi = new_wi "participant x"

        wi.fields << OpenWFE::Extras::Field.new_field("toto", "a")
        wi.fields << OpenWFE::Extras::Field.new_field("toto", "b")

        assert_raise ActiveRecord::StatementInvalid do
            wi.save
        end

        wis = OpenWFE::Extras::Workitem.find :all

        assert_equal 0, wis.size
    end

    def test_1

        wi = new_wi "participant x"

        wi.fields << OpenWFE::Extras::Field.new_field("toto", "a")
        wi.fields << OpenWFE::Extras::Field.new_field("list", [ 1, 2, "trois" ])
        wi.fields << OpenWFE::Extras::Field.new_field("smurf", "")
        wi.fields << OpenWFE::Extras::Field.new_field("grand schtroumpf", " ")

        wi.save

        wis = OpenWFE::Extras::Workitem.find :all

        assert_equal 1, wis.size

        assert_equal "a", wi.field(:toto).value
        assert_equal [ 1, 2, "trois" ], wi.field(:list).value
        assert_equal " ", wi.field("grand schtroumpf").value
        assert_equal "", wi.field(:smurf).value
    end

    def test_2

        wi = new_wi "participant y"
        wi.fields << OpenWFE::Extras::Field.new_field("toto", "a")
        wi.store_name = "store_a"
        wi.save

        wi = new_wi "participant y"
        wi.fields << OpenWFE::Extras::Field.new_field("toto", "b")
        wi.store_name = "store_b"
        wi.save

        wi = new_wi "participant z"
        wi.fields << OpenWFE::Extras::Field.new_field("toto", "c")
        wi.store_name = "store_c"
        wi.save

        wis = OpenWFE::Extras::Workitem.find :all

        assert_equal 3, wis.size

        wl = OpenWFE::Extras::Workitem.find_all_by_participant_name "participant y"

        assert_equal 2, wl.size

        values = [ wl[0].field(:toto).value, wl[1].field(:toto).value ].sort

        assert_equal [ "a", "b" ], values

        assert_equal(
            2, 
            OpenWFE::Extras::Workitem.find_in_stores([ "store_a", "store_b" ]).size)
        assert_equal(
            1, 
            OpenWFE::Extras::Workitem.find_in_stores([ "store_a", "store_b" ])["store_a"].size)
        assert_equal(
            1, 
            OpenWFE::Extras::Workitem.find_in_stores([ "store_a", "store_b" ])["store_b"].size)
        assert_equal(
            nil, 
            OpenWFE::Extras::Workitem.find_in_stores([ "store_a", "store_b" ])["store_c"])
    end

    def test_3

        wi = new_wi "participant 3", { "toto" => "a" }
        wi.save!

        wi.replace_fields({ "toto" => "nada", "tada" => { 1 => 10 } })
        wi.save!

        wi = OpenWFE::Extras::Workitem.find_by_participant_name "participant 3"

        assert_equal({ "toto"=>"nada", "tada"=> {1 => 10} }, wi.fields_hash) 
    end

    def test_4

        wi = new_wi "paetrus", { "message" => "hello world!" }
        wi.save!
        wi = new_wi "philippe", { "color" => "blue" }
        wi.save!
        wi = new_wi "peter", { "color" => "red" }
        wi.save!
        wi = new_wi "petra", { "color" => "yellow" }
        wi.save!

        assert_equal 1, OpenWFE::Extras::Workitem.search("blue").size
        assert_equal 0, OpenWFE::Extras::Workitem.search("lu").size

        assert_equal 3, OpenWFE::Extras::Workitem.search("color").size
        assert_equal 2, OpenWFE::Extras::Workitem.search("pet%").size
        assert_equal 0, OpenWFE::Extras::Workitem.search("pet").size

        assert_equal 1, OpenWFE::Extras::Workitem.search("hello").size
    end

    def test_5

        wi = new_wi "philippe", { "color" => "blue" }
        wi.store_name = "s1"
        wi.save!
        wi = new_wi "peter", { "color" => "red" }
        wi.store_name = "s1"
        wi.save!
        wi = new_wi "petra", { "color" => "yellow" }
        wi.store_name = "s2"
        wi.save!

        assert_equal 1, OpenWFE::Extras::Workitem.search("blue").size
        assert_equal 2, OpenWFE::Extras::Workitem.search("color", "s1").size
        assert_equal 1, OpenWFE::Extras::Workitem.search("pet%", [ "s2" ]).size
        assert_equal 2, OpenWFE::Extras::Workitem.search("pet%", [ "s1", "s2" ]).size
        assert_equal 0, OpenWFE::Extras::Workitem.search("pet").size
    end

    def _test_6

        require 'date'

        wi = OpenWFE::InFlowWorkItem.new
        wi.fei = new_fei

        wi.name = "Maarten"
        wi.birthdate = Date.new

        awi = OpenWFE::Extras::Workitem.from_owfe_workitem wi
        awi.save!

        awi = OpenWFE::Extras::Workitem.find awi.id
        wi2 = awi.as_owfe_workitem

        assert_equal wi.fields, wi2.fields
    end

    # 
    # this test is used to verify the yattributes functionalty used by
    # "compact_workitems"
    # 
    def test_7

        wi = OpenWFE::InFlowWorkItem.new
        wi.fei = new_fei

        wi.name = "Tomaso"
        wi.surname = "Tosolini"
        wi.attributes["a_hash"] = { 
            "a_key" => "a_value",
            "b_key" => { "ba_key" => "ba_value" } 
        }
            #
            # let's set some fields...

        wi.attributes["compact_workitems"] = true
            #
            # with this we enable the following function the behave in
            # the comapct_workitems way

        awi = OpenWFE::Extras::Workitem.from_owfe_workitem wi
            #
            # in flow workitem to workitem(see activeparticipants)
 
        awi = OpenWFE::Extras::Workitem.find awi.id
            # 
            # let's reload it 

        wi2 = awi.as_owfe_workitem
            #
            # workitem back to in flow workitem

        assert_equal wi.attributes, wi2.attributes
    end

    def test_8

        wi = OpenWFE::InFlowWorkItem.new
        wi.fei = new_fei

        wi.attributes["compact_workitems"] = true
        wi.participant_name = "part x"
        wi.attributes = { "toto" => "a" }

        awi = OpenWFE::Extras::Workitem.from_owfe_workitem wi
            #
            # in flow workitem to workitem(see activeparticipants)

        awi.replace_fields({ "toto" => "nada", "tada" => { 1 => 10 } })

        awi = OpenWFE::Extras::Workitem.find_by_participant_name "part x"

        assert_equal({ "toto"=>"nada", "tada"=> {1 => 10} }, awi.fields_hash)
    end

    #
    # big fat workitem field
    #
    def test_9

        t = (0..700).to_a.inject("") { |r, i| r << i.to_s } + " red"

        wi = OpenWFE::InFlowWorkItem.new
        wi.fei = new_fei
        wi.participant_name = "part 9"
        wi['fat_field'] = t

        awi = OpenWFE::Extras::Workitem.from_owfe_workitem wi

        awi = OpenWFE::Extras::Workitem.find_by_participant_name "part 9"

        assert_equal t, awi.fields_hash['fat_field']

        f = awi.fields[0]
        assert_equal "String", f.vclass
        assert_equal t, f.yvalue
        assert_nil f.svalue

        assert_equal 0, OpenWFE::Extras::Workitem.search("blue").size
        assert_equal 1, OpenWFE::Extras::Workitem.search("% red").size

        #p awi.connection.native_database_types[:string][:limit]
    end

end

