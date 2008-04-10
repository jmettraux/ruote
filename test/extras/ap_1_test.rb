

require 'test/unit'

require 'extras/ap_test_base'

require 'openwfe/extras/participants/activeparticipants'


class Active1Test < Test::Unit::TestCase
    include ApTestBase

    def setup

        OpenWFE::Extras::Workitem.destroy_all
            # let's make sure there are no workitems left
    end

    def teardown

        OpenWFE::Extras::Workitem.destroy_all
    end
    
    #
    # tests

    def test_0

        wi = new_wi "participant alpha"

        (1..100).to_a.each do |i|
            Thread.new do

                sleep rand()

                f = OpenWFE::Extras::Field.new_field(
                    "some_field_#{i}", "val_#{i}")

                wi.fields << f

                print "\n/// added #{f.id} #{f.fkey}, #{f.svalue}"
            end
        end

        sleep 2

        wi.save!

        assert_equal 100, wi.fields.size
    end

end

