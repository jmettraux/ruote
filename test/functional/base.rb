
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Sep 20 23:40:10 JST 2008
#

require 'fileutils'

require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/engine_helper.rb'

require 'ruote/engine'
require 'ruote/log/test_logger'


module FunctionalBase

  def setup

    @tracer = Tracer.new

    ac = {}

    #class << ac
    #  alias :old_put :[]=
    #  def []= (k, v)
    #    raise("!!!!! #{k.class}\n#{k.inspect}") \
    #      if k.class != String and k.class != Symbol
    #    old_put(k, v)
    #  end
    #end
    #  #
    #  # useful for tracking misuses of the application context

    ac[:s_tracer] = @tracer
    #ac[:ruby_eval_allowed] = true
    #ac[:definition_in_launchitem_allowed] = true

    @engine = determine_engine_class(ac).new(ac)

    @terminated_processes = []
    @engine.wqueue.subscribe(:processes) do |eclass, emsg, eargs|
      @terminated_processes << eargs[:wfid] if emsg == :terminate
    end
  end

  def teardown

    #$OWFE_LOG.level = Logger::INFO
    @engine.stop
  end

  # launch_thing is a process definition or a launch item
  #
  def assert_trace (launch_thing, expected_trace, opts={})

    fei = @engine.launch(launch_thing, opts[:launch_opts] || {})

    wait_for(fei, opts)

    yield(@engine) if block_given?

    assert_engine_clean(fei, opts)

    assert_equal(expected_trace, @tracer.to_s) if expected_trace

    purge_engine unless opts[:no_purge]

    fei
  end

  protected

  def verbose (on=true)
    if on
      @engine.add_service(:s_logger, Ruote::TestLogger)
    else
      @engine.remove_service(:s_logger)
    end
  end

  def logger
    @engine.context[:s_logger]
  end

  def wait_for (fei, opts={})
    Thread.pass
    return if @terminated_processes.include?(fei.wfid)
    @engine.wait_for(fei)
  end

  def wait
    Thread.pass
    sleep 0.001
  end

  def assert_engine_clean (fei=nil, opts={})

    assert_no_errors(fei, opts)
    assert_no_remaining_expressions(fei, opts)
  end

  def assert_no_errors (fei, opts)

    return # TODO : wire back in when

    return if opts[:ignore_errors]

    ps = if fei
      @engine.process_status(fei.wfid)
    else
      @engine.process_statuses.values.first
    end

    return unless ps
    return if ps.errors.size == 0

    # TODO : implement 'banner' function

    puts '-' * 80
    puts 'caught process error(s)'
    puts
    ps.errors.values.each do |e|
      puts "  ** error : #{e.error_class} \"#{e.stacktrace}\""
    end
    puts '-' * 80

    puts_trace_so_far

    flunk 'caught process error(s)'
  end

  def assert_no_remaining_expressions (fei, opts)

    return if opts[:ignore_errors]

    expcount = @engine.expstorage.size
    #return if expcount == 1
    return if expcount == 0

    #50.times { Thread.pass }
    #expcount = @engine.expstorage.size
    #return if expcount == 1

    puts '-' * 80
    puts 'too many expressions left in storage'
    puts
    puts "this test's wfid : #{fei.wfid}"
    puts
    puts 'left :'
    puts
    puts @engine.expstorage.to_s
    puts
    puts '-' * 80

    puts_trace_so_far

    flunk 'too many expressions left in storage'
  end

  def purge_engine

    @engine.context.values.each do |s|
      s.purge if s.respond_to?(:purge)
    end
    FileUtils.rm_rf('work')
  end

  def puts_trace_so_far

    #puts '. ' * 40
    puts 'trace so far'
    puts '---8<---'
    puts @tracer.to_s
    puts '--->8---'
    puts '. ' * 40
  end
end

class Tracer
  def initialize
    super
    @trace = ''
  end
  def to_s
    @trace.to_s.strip
  end
  def << s
    @trace << s
  end
  def clear
    @trace = ''
  end
  def puts s
    @trace << "#{s}\n"
  end
end

