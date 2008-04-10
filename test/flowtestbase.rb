#_
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 15:41:44 JST 2006
#
# somewhere between Philippina and the Japan
#

require 'rubygems'
require 'test/unit'

require 'openwfe/workitem'
require 'openwfe/engine/engine'
require 'openwfe/rudefinitions'
require 'openwfe/participants/participants'

require 'rutest_utils'


$WORKFLOW_ENGINE_CLASS = OpenWFE::Engine

persistence = ENV["__persistence__"]


if persistence == "pure-persistence"

    require "openwfe/engine/file_persisted_engine"
    $WORKFLOW_ENGINE_CLASS = OpenWFE::FilePersistedEngine

elsif persistence == "cached-persistence"

    require "openwfe/engine/file_persisted_engine"
    $WORKFLOW_ENGINE_CLASS = OpenWFE::CachedFilePersistedEngine

elsif persistence == "db-persistence"

    require 'extras/active_connection'
    require 'openwfe/extras/engine/db_persisted_engine'
    $WORKFLOW_ENGINE_CLASS = OpenWFE::Extras::DbPersistedEngine

elsif persistence == "cached-db-persistence"

    require 'extras/active_connection'
    require 'openwfe/extras/engine/db_persisted_engine'
    $WORKFLOW_ENGINE_CLASS = OpenWFE::Extras::CachedDbPersistedEngine
end
    

puts
puts "testing with engine of class " + $WORKFLOW_ENGINE_CLASS.to_s
puts

module FlowTestBase

    attr_reader \
        :engine, :tracer

    #
    # SETUP
    #
    def setup

        @engine = $WORKFLOW_ENGINE_CLASS.new

        #@terminated_processes = []
        #@engine.get_expression_pool.add_observer(:terminate) do |c, fe, wi|
        #    @terminated_processes << fe.fei.wfid
        #end

        @engine.application_context[:ruby_eval_allowed] = true

        @tracer = Tracer.new
        @engine.application_context["__tracer"] = @tracer

        @engine.register_participant('pp-workitem') do |workitem|

            puts
            require 'pp'; pp workitem
            puts
        end

        @engine.register_participant('pp-fields') do |workitem|

            workitem.attributes.keys.sort.each do |field|
                next if field == "___map_type" or field == "__result__"
                next if field == "params"
                @tracer << "#{field}: #{workitem.attributes[field]}\n"
            end
            @tracer << "--\n"
        end

        @engine.register_participant 'test-.*', OpenWFE::PrintParticipant.new

        @engine.register_participant('block-participant') do |workitem|
            @tracer << "the block participant received a workitem"
            @tracer << "\n"
        end

        @engine.register_participant('p-toto') do |workitem|
            @tracer << "toto"
        end
    end

    #
    # TEARDOWN
    #
    def teardown

        if @engine
            $OWFE_LOG.level = Logger::INFO
            @engine.stop 
        end
    end

    protected

        def log_level_to_debug
            $OWFE_LOG.level = Logger::DEBUG
        end

        def print_exp_list (l)
            puts
            l.each do |fexp|
                puts "   - #{fexp.fei.to_debug_s}"
            end
            puts
        end

        def name_of_test
            s = caller(1)[0]
            i = s.index('`')
            #s = s[i+1..s.length-2]
            s = s[i+6..s.length-2]
            s
        end

        #
        # some tests return quickly, leverage the @terminated_processes
        # of the test engine to determine those processes that are
        # already over...
        #
        def wait_for (fei)

            #return if @terminated_processes.include?(fei.wfid)
            @engine.wait_for(fei)  
        end

        #
        # dotest()
        #
        def dotest (
            flowDef, expectedTrace, join=false, allowRemainingExpressions=false)

            @tracer.clear

            li = if flowDef.kind_of? OpenWFE::LaunchItem
                flowDef
            else
                OpenWFE::LaunchItem.new(flowDef)
            end

            #start = Time.now.to_f

            fei = @engine.launch li

            $OWFE_LOG.info { "dotest() launched #{fei.to_s}" }

            if join.is_a?(Numeric)
                sleep join
            else
                #@engine.wait_for fei
                wait_for fei
            end

            #puts "// took #{Time.now.to_f - start} s"

            trace = @tracer.to_s

            #puts "...'#{trace}' ?= '#{expectedTrace}'"

            if expectedTrace.kind_of?(Array)

                result = expectedTrace.find do |etrace|
                    trace == etrace
                end
                assert(
                    (result != nil),
                    """flow failed : 
                   
  trace doesn't correspond to any of the expected traces...

  traced :
                    
'#{trace}'

""")
            elsif expectedTrace.kind_of?(Regexp)

                assert trace.match(expectedTrace)
            else

                assert(
                    trace == expectedTrace,
                    """flow failed : 

  traced :
                    
'#{trace}'

  but was expecting :

'#{expectedTrace}'
""")
            end

            if allowRemainingExpressions

                purge_engine

                return fei
            end

            exp_storage = engine.get_expression_storage
            view = exp_storage.to_s
            size = exp_storage.size

            if size != 1
                puts
                puts "    remaining expressions : #{size}"
                puts
                puts view
                puts
                puts OpenWFE::caller_to_s(0, 2)
                puts

                purge_engine
            end

            assert_equal(
                1,
                size,
                "there are expressions remaining in the expression pool " +
                "(right now : #{exp_storage.length})")

            fei
        end

        def purge_engine

            @engine.get_expression_storages.each do |storage|
                storage.purge
            end
        end

        def assert_trace (desired_trace)

            assert_equal desired_trace, @tracer.to_s
        end

end

#
# A bunch of methods for testing the journal component
#
module JournalTestBase

    def get_journal

        @engine.get_journal
    end

    def get_error_count (wfid)

        fn = get_journal.workdir + "/" + wfid + ".journal"

        get_journal.flush_buckets

        events = get_journal.load_events(fn)

        error_count = 0
        events.each { |evt| error_count += 1 if evt[0] == :error }

        error_count
    end
end

