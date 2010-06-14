
#
# testing ruote
#
# Sat Sep 20 23:40:10 JST 2008
#

require 'fileutils'

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require File.join(File.dirname(__FILE__), 'storage_helper.rb')

require 'ruote/engine'
require 'ruote/worker'
require 'ruote/parser/ruby_dsl'


module FunctionalBase

  def setup

    #require 'ruote/util/look'
    #Ruote::Look.dump_lsof
    #Ruote::Look.dump_lsof_count

    @engine =
      Ruote::Engine.new(
        Ruote::Worker.new(
          determine_storage(
            's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ])))

    #p @engine.storage.class

    @tracer = Tracer.new

    @engine.add_service('tracer', @tracer)

    noisy if ARGV.include?('-n')

    #noisy # uncommented, it makes all the tests noisy
  end

  def teardown

    @engine.shutdown
    @engine.context.storage.purge!
  end

  def assert_log_count (count, &block)

    c = @engine.context.logger.log.select(&block).size

    #logger.to_stdout if ( ! @engine.context[:noisy]) && c != count

    assert_equal count, c
  end

  #   assert_trace(*expected_traces, pdef)
  #   assert_trace(*expected_traces, fields, pdef)
  #
  def assert_trace (*args)

    pdef = args.pop
    fields = args.last.is_a?(Hash) ? args.pop : {}
    expected_traces = args.collect { |et| et.is_a?(Array) ? et.join("\n") : et }

    wfid = @engine.launch(pdef, fields)

    wait_for(wfid)

    #yield(@engine) if block_given?

    assert_engine_clean(wfid)

    if expected_traces.length > 0
      ok, nok = expected_traces.partition { |et| @tracer.to_s == et }
      assert_equal(nok.first, @tracer.to_s) if ok.empty?
    end

    assert(true)
      # so that the assertion count matches

    wfid
  end

  def logger

    @engine.context.logger
  end

  protected

  def noisy (on=true)

    puts "\nnoisy " + caller[0] if on
    @engine.context.logger.noisy = true
  end

  def wait_for (*wfid_or_part)

    @engine.wait_for(*wfid_or_part)
  end

  def assert_engine_clean (wfid)

    assert_no_errors(wfid)
    assert_no_remaining_expressions(wfid)
  end

  def assert_no_errors (wfid)

    errors = @engine.storage.get_many('errors', /#{wfid}$/)

    return if errors.size == 0

    puts
    puts '-' * 80
    puts 'remaining process error(s)'
    puts
    errors.each do |e|
      puts "  ** #{e['message']}"
      puts e['trace']
    end
    puts '-' * 80

    puts_trace_so_far

    flunk 'remaining process error(s)'
  end

  def assert_no_remaining_expressions (wfid)

    expcount = @engine.storage.get_many('expressions').size
    return if expcount == 0

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
    puts @engine.context.storage.dump('expressions')
    puts
    puts '-' * 80

    puts_trace_so_far

    flunk 'too many expressions left in storage'
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
  attr_reader :s
  def initialize
    super
    @s = ''
  end
  def to_s
    @s.to_s.strip
  end
  def to_a
    to_s.split("\n")
  end
  def << s
    @s << s
  end
  def clear
    @s = ''
  end
  def puts (s)
    @s << "#{s}\n"
  end
end

