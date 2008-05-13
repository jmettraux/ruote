
#
# Benchmarking / testing Ruote
#
# John Mettraux at openwfe.org
#
# Tue May 13 15:03:41 JST 2008
#

require 'rubygems'

require 'openwfe/def'

require 'flowtestbase'


class FlowTestRecursion < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end

    #
    # test 0
    #

    #N = 500
    N = 100

    #
    # Test0, N=100
    #
    # Tue May 13 17:24:53 JST 2008
    #
    # without substitution :
    # q : 2.72s
    # p : 752s
    #
    # with substitution :
    # q : 2.67s
    # p : 715s
    # (c : 10s)
    #
    # => :(
    #
    # with substitution : stack grows to 515 exps
    # without : stack grows to 615 exps
    #

    #
    # chaining N steps
    #
    # (took 39 seconds the first time for N = 500)
    #
    class Test0 < OpenWFE::ProcessDefinition

        step0

        (0..N).each do |i|
            define "stage#{i}" do
                sequence do
                    _print "stage#{i}"
                    set :f => 'outcome', :val => "step#{i+1}"
                    #_print "${r:fexp.get_expression_storage.size}" if i == N
                end
            end
            define "step#{i}" do
                step "stage#{i}"
            end
        end

        define "step#{N+1}" do
            _print "over."
        end
    end

    #
    # testing against a sequence of N subprocess calls
    #
    # (took 6 seconds the first time for N = 500)
    # (just chaining N 'print "stage#{i}"' takes 0.7 second)
    #
    class Test0b < OpenWFE::ProcessDefinition
        sequence do
            (0..N).each do |i|
                subprocess :ref => "stage#{i}"
            end
            _print "over."
        end
        (0..N).each do |i|
            define "stage#{i}" do
                sequence do
                    _print "stage#{i}"
                end
            end
        end
    end

    def test_0

        dotest Test0, (0..N).collect { |i| "stage#{i}" }.join("\n") + "\nover."
        #dotest Test0b, (0..N).collect { |i| "stage#{i}" }.join("\n") + "\nover."
    end

end

