
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Sep 20 23:40:10 JST 2008
#

require 'fileutils'

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require File.join(File.dirname(__FILE__), 'engine_helper.rb')

require 'ruote/engine'
require 'ruote/worker'


module FunctionalBase

  def setup

    @tracer = Tracer.new

    @engine =
      Ruote::Engine.new(
        Ruote::Worker.new(
          determine_storage(
            's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ],
            's_tracer' => @tracer)))
  end

  def teardown

    purge_engine

    @engine.shutdown
  end

  def assert_log_count (count, &block)

    c = @engine.context.logger.log.select(&block).size

    #logger.to_stdout if ( ! @engine.context[:noisy]) && c != count

    assert_equal count, c
  end

  # launch_thing is a process definition or a launch item
  #
  def assert_trace (launch_thing, *expected_traces)

    opts = expected_traces.last.is_a?(Hash) ? expected_traces.pop : {}

    expected_traces = expected_traces.collect do |et|
      et.is_a?(Array) ? et.join("\n") : et
    end

    wfid = @engine.launch(launch_thing, opts[:launch_opts] || {})

    #if t = opts[:sleep]; sleep t; end

    wait_for(wfid)

    yield(@engine) if block_given?

    assert_engine_clean(wfid, opts)

    if expected_traces.length > 0
      ok, nok = expected_traces.partition { |et| @tracer.to_s == et }
      assert_equal(nok.first, @tracer.to_s) if ok.empty?
    end

    assert(true)
      # so that the assertion count matche

    wfid
  end

  def logger

    @engine.context.logger
  end

  protected

  def noisy (on=true)

    puts "\nnoisy " + caller[0] if on
    @engine.context[:noisy] = on
  end

  def wait_for (wfid_or_part)

    @engine.context.logger.wait_for(wfid_or_part)
  end

  def assert_engine_clean (wfid=nil, opts={})

    assert_no_errors(wfid, opts)
    assert_no_remaining_expressions(wfid, opts)
  end

  def assert_no_errors (wfid, opts)

    return if opts[:ignore_errors]

    ps = @engine.process(wfid)

    return unless ps
    return if ps.errors.size == 0

    # TODO : implement 'banner' function

    puts
    puts '-' * 80
    puts 'caught process error(s)'
    puts
    ps.errors.each do |e|
      puts "  ** #{e.message}"
      puts e.trace
    end
    puts '-' * 80

    puts_trace_so_far

    flunk 'caught process error(s)'
  end

  def assert_no_remaining_expressions (wfid, opts)

    return if opts[:ignore_remaining_expressions]

    expcount = @engine.storage.get_many('expressions').size
    return if expcount == 0

    #50.times { Thread.pass }
    #expcount = @engine.expstorage.size
    #return if expcount == 0

    tf, _, tn = caller[2].split(':')

    puts
    puts '-' * 80
    puts 'too many expressions left in storage'
    puts
    puts "this test : #{tf}"
    puts "            #{tn}"
    puts
    puts "this test's wfid : #{wfid}"
    puts
    puts 'left :'
    puts
    puts @engine.context.torage.to_s
    puts
    puts '-' * 80

    puts_trace_so_far

    flunk 'too many expressions left in storage'
  end

  def purge_engine

    @engine.purge!

    FileUtils.rm_rf('work')
  end

  def puts_trace_so_far

    #puts '. ' * 40
    puts 'trace so far'
    puts '---8<---'
    puts @tracer.to_s
    puts '--->8---'
    puts
  end
end

class Tracer
  attr_reader :trace
  def initialize
    super
    @trace = ''
  end
  def to_s
    @trace.to_s.strip
  end
  def to_a
    to_s.split("\n")
  end
  def << s
    @trace << s
  end
  def clear
    @trace = ''
  end
  def puts (s)
    @trace << "#{s}\n"
  end
end

