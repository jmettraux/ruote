
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'flowtestbase'


class FlowTest5 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    def test_sleep_0
        dotest(
'''<process-definition name="sleep_0" revision="0">
    <sequence>
        <sleep for="2s" />
        <print>alpha</print>
    </sequence>
</process-definition>''', 
            "alpha", 
            true)
    end

    def test_sleep_1
        dotest(
'''<process-definition name="sleep_1" revision="0">
    <concurrence>
        <sequence>
            <sleep for="2s" />
            <print>alpha</print>
        </sequence>
        <print>bravo</print>
    </concurrence>
</process-definition>''', 
            """bravo
alpha""", 
            true)
    end

    def test_sleep_2
        dotest(
'''<process-definition name="sleep_2" revision="0">
    <sequence>
        <sleep until="${ruby:Time.new() + 4}" />
        <print>alpha</print>
    </sequence>
</process-definition>''', 
            "alpha", 
            true)
    end

    def test_sleep_3
        dotest(
'''<process-definition name="sleep_3" revision="0">
    <sequence>
        <sleep for="900" />
        <print>alpha</print>
    </sequence>
</process-definition>''', "alpha", true)
    end

    #
    # Test 4
    #

    class Test4 < OpenWFE::ProcessDefinition
        _sleep "10s"
    end

    def test_sleep_4

        fei = launch Test4

        sleep 0.250
        
        jobs = @engine.get_scheduler.find_jobs OpenWFE::SleepExpression.name

        assert_equal 1, jobs.size

        @engine.cancel_process fei

        sleep 0.300
    end

    #
    # Test 5
    #

    class Test5 < OpenWFE::ProcessDefinition
        _sleep "10s", :scheduler_tags => "a, b"
    end

    def test_sleep_5

        fei = launch Test5

        sleep 0.250

        assert_equal 1, @engine.get_scheduler.find_jobs("a").size
        assert_equal 1, @engine.get_scheduler.find_jobs("b").size

        @engine.cancel_process fei

        sleep 0.300
    end

end

