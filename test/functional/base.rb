
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Sep 20 23:40:10 JST 2008
#

require File.dirname(__FILE__) + '/../test_helper.rb'
require File.dirname(__FILE__) + '/engine_helper.rb'

require 'openwfe/engine'


module FunctionalBase

  def setup

    @tracer = Tracer.new

    ac = {}

    class << ac
      alias :old_put :[]=
      def []= (k, v)
        raise("!!!!! #{k.class}\n#{k.inspect}") \
          if k.class != String and k.class != Symbol
        old_put(k, v)
      end
    end
      #
      # useful for tracking misuses of the application context

    ac['__tracer'] = @tracer
    ac[:ruby_eval_allowed] = true
    ac[:definition_in_launchitem_allowed] = true

    @engine = determine_engine_class(ac).new(ac)

    @terminated_processes = []
    @engine.get_expression_pool.add_observer(:terminate) do |c, fe, wi|
      @terminated_processes << fe.fei.wfid
      #p [ :terminated, @terminated_processes ]
    end
  end

  def teardown

    $OWFE_LOG.level = Logger::INFO
    @engine.stop
  end

  #
  # returns true when running on a Ruby 1.8.x like interpreter
  #
  def ruby18

    RUBY_VERSION.match(/^1\.8\./)
  end

  #
  # launch_thing is a process definition or a launch item
  #
  def assert_trace (launch_thing, expected_trace, opts={})

    fei = @engine.launch(launch_thing, opts[:launch_opts] || {})

    wait(fei, opts)

    yield(@engine) if block_given?

    assert_engine_clean(fei, opts)

    assert_equal(expected_trace, @tracer.to_s) if expected_trace

    purge_engine unless opts[:no_purge]

    fei
  end

  protected

  def log_level_to_debug

    $OWFE_LOG.level = Logger::DEBUG
  end

  def wait (fei, opts={})

    #opts[:wait] ?
    #  @engine.wait_for(fei) :
    #  sleep(opts[:after] || 0.350)

    Thread.pass
    return if @terminated_processes.include?(fei.wfid)
    @engine.wait_for(fei)
  end

  def assert_engine_clean (fei=nil, opts={})

    assert_no_errors(fei, opts)
    assert_no_remaining_expressions(fei, opts)
  end

  def assert_no_errors (fei, opts)

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

    expcount = @engine.get_expression_storage.size
    return if expcount == 1

    50.times { Thread.pass }
    expcount = @engine.get_expression_storage.size
    return if expcount == 1

    puts '-' * 80
    puts 'too many expressions left in storage'
    puts
    puts "this test's wfid : #{fei.wfid}"
    puts
    puts 'left :'
    puts
    puts @engine.get_expression_storage.to_s
    puts
    puts '-' * 80

    puts_trace_so_far

    flunk 'too many expressions left in storage'
  end

  def purge_engine

    @engine.application_context.values.each do |s|
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

