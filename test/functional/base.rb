
#
# testing ruote
#
# Sat Sep 20 23:40:10 JST 2008
#

require 'fileutils'

require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../storage_helper', __FILE__)
require File.expand_path('../signals', __FILE__)

require 'ruote'


#
# Most of the functional tests extend this class.
#
module FunctionalBase

  # For functional tests that want to provide their own setup or teardown
  # and still have an opportunity to call this base's setup/teardown
  #
  def self.included(target)

    target.class_eval do
      alias base_setup setup
      alias base_teardown teardown
    end
  end

  def setup

    if ARGV.include?('-T') || ARGV.include?('-N') || ENV['NOISY'] == 'true'
      p self.class
    end

    #require 'ruote/util/look'
    #Ruote::Look.dump_lsof
    #Ruote::Look.dump_lsof_count
      #
      # uncomment this when "too many open files"

    sto = determine_storage({})

    @dashboard = Ruote::Dashboard.new(
      sto.class.name.match(/Worker$/) ? sto : Ruote::Worker.new(sto))

    @engine = @dashboard
      # for 'backward compatibility'

    $_test = self
    $_dashboard = @dashboard
      #
      # handy when hijacking (https://github.com/ileitch/hijack)
      # or flinging USR2 at the test process

    @tracer = Tracer.new

    Ruote::BlockParticipant.class_eval do
      def tracer
        @context.tracer
      end
      def stash
        @context.stash
      end
    end

    @dashboard.add_service('tracer', @tracer)
    @dashboard.add_service('stash', {})

    noisy if ARGV.include?('-N') || ENV['NOISY'].to_s == 'true'
  end

  def teardown

    return if @dashboard.nil?

    @dashboard.shutdown
    @dashboard.context.storage.purge!
    @dashboard.context.storage.close if @dashboard.context.storage.respond_to?(:close)
  end

  def stash

    @dashboard.context.stash
  end

  def assert_log_count(count, &block)

    c = @dashboard.context.logger.log.select(&block).size

    #logger.to_stdout if ( ! @dashboard.context[:noisy]) && c != count

    assert_equal count, c
  end

  #   assert_trace(*expected_traces, pdef)
  #   assert_trace(*expected_traces, fields, pdef)
  #
  def assert_trace(*args)

    if args.last == :clear
      args.pop
      @tracer.clear
    end

    pdef = args.pop
    fields = args.last.is_a?(Hash) ? args.pop : {}
    expected_traces = args.collect { |et| et.is_a?(Array) ? et.join("\n") : et }

    wfid = @dashboard.launch(pdef, fields)

    r = wait_for(wfid)

    assert_engine_clean(wfid)

    trace = r['workitem']['fields']['_trace']
    trace = trace ? trace.join('') : @tracer.to_s

    if expected_traces.length > 0
      ok, nok = expected_traces.partition { |et| trace == et }
      assert_equal(nok.first, trace) if ok.empty?
    end

    assert(true)
      # so that the assertion count matches

    wfid
  end

  def logger

    @dashboard.context.logger
  end

  protected

  def noisy(on=true)

    @dashboard.context.logger.noisy = true
  end

  def wait_for(*wfid_or_part)

    @dashboard.wait_for(*wfid_or_part)
  end

  def assert_engine_clean(wfid)

    assert_no_errors(wfid)
    assert_no_remaining_expressions(wfid)
  end

  def assert_no_errors(wfid)

    errors = @dashboard.storage.get_many('errors', /#{wfid}$/)

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

  def assert_no_remaining_expressions(wfid)

    expcount = @dashboard.storage.get_many('expressions').size
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
    puts @dashboard.context.storage.dump('expressions')
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

#
# Re-opening workitem for a shortcut to a '_trace' field
#
class Ruote::Workitem
  def trace
    @h['fields']['_trace'] ||= []
  end
end

#
# Our tracer class.
#
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
  def puts(s)
    @s << "#{s}\n"
  end
end

