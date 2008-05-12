
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon May 12 14:12:54 JST 2008
#

require 'rubygems'

require 'test/unit'

require 'openwfe/util/treechecker'

#
# testing expression conditions
#

class TreeCheckerTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    def test_0

        assert_safe "1+1"
        assert_unsafe "exit"
        assert_unsafe "puts $BATEAU"
        assert_unsafe "def surf }"
    end

    def test_1

        assert_unsafe "abort"
        assert_unsafe "abort; puts 'ok'"
    end

    def test_2

        assert_unsafe "puts 'ok'; abort"
            # this one is weird, it does a stack level too deep
    end

    protected

        def assert_safe (code)

            assert check(code)
        end

        def assert_unsafe (code)

            assert (not check(code))
        end

        def check (code)

            begin

                OpenWFE::TreeChecker.check code

            rescue Exception => e
                #puts e
                #puts e.backtrace
                return false
            end
            
            true
        end
end
