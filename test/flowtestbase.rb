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

    $OWFE_LOG.info(
      "setup() started engine #{@engine.object_id} @ #{caller[-1]}")

    @terminated_processes = []
    @engine.get_expression_pool.add_observer(:terminate) do |c, fe, wi|
      @terminated_processes << fe.fei.wfid
      #p [ :terminated, @terminated_processes ]
    end
    #@terminated = false
    #@engine.get_expression_pool.add_observer(:terminate) do |c, fe, wi|
    #  @terminated = true
    #end

    @engine.application_context[:ruby_eval_allowed] = true
    @engine.application_context[:definition_in_launchitem_allowed] = true

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
      s[i+6..s.length-2]
    end

    #
    # some tests return quickly, leverage the @terminated_processes
    # of the test engine to determine those processes that are
    # already over...
    #
    def wait_for (fei)

      #for i in (0..42)
      for i in (0..217)
        Thread.pass
        return if @terminated_processes.include?(fei.wfid)
        #return if @terminated
      end

      @engine.wait_for fei
    end

    #
    # calling
    #
    #   launch li
    #
    # instead of
    #
    #   @engine.launch li
    #
    # ensures that the logs will contain a mention of the wfid of the
    # flow just started along with the test method (and it's location
    # in its source file).
    #
    def launch (li)

      fei = @engine.launch li

      $OWFE_LOG.info(
        "dotest() launched #{fei.to_short_s} "+
        "@ #{caller[1]} on engine #{@engine.object_id}")

      fei
    end

    #
    # dotest()
    #
    def dotest (
      flowDef,
      expected_trace,
      join=false,
      allow_remaining_expressions=false)

      @tracer.clear

      li = if flowDef.kind_of?(OpenWFE::LaunchItem)
        flowDef
      else
        OpenWFE::LaunchItem.new flowDef
      end

      #start = Time.now.to_f

      fei = launch li

      if join.is_a?(Numeric)
        sleep join
      else
        wait_for fei
      end

      #puts "// took #{Time.now.to_f - start} s"


      trace = @tracer.to_s

      #if trace == ''
      #  Thread.pass; sleep 0.350
      #  trace = @tracer.to_s
      #end
        #
        # occurs when the tracing is done from a participant
        # (participant dispatching occurs in a thread)

      #for i in  0..70
      #  Thread.pass; sleep 0.140
      #  trace = @trace.to_s
      #  p [ :trace, trace ]
      #  break if trace != ''
      #end if trace == ''

      #puts "...'#{trace}' ?= '#{expected_trace}'"

      if expected_trace.is_a?(Array)

        result = expected_trace.find do |etrace|
          trace == etrace
        end
        assert(
          (result != nil),
          """flow failed :

  trace doesn't correspond to any of the expected traces...

  traced :

'#{trace}'

""")
      elsif expected_trace.kind_of?(Regexp)

        assert trace.match(expected_trace)
      else

        assert(
          trace == expected_trace,
          """flow failed :

  traced :

'#{trace}'

  but was expecting :

'#{expected_trace}'
""")
      end

      if allow_remaining_expressions

        purge_engine

        return fei
      end

      #Thread.pass; sleep 0.003; Thread.pass

      exp_storage = engine.get_expression_storage

      view = exp_storage.to_s
      size = exp_storage.size

      if size != 1
        sleep 0.350
        view = exp_storage.to_s
        size = exp_storage.size
      end

      if size != 1
        puts
        puts "  remaining expressions : #{size}"
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

    #
    # makes sure to purge the engine's expression storage
    #
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

    events.inject(0) { |r, evt| r += 1 if evt[0] == :error; r }
  end
end

