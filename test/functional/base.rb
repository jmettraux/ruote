
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
    ac['__tracer'] = @tracer
    ac[:definition_in_launchitem_allowed] = true

    @engine = determine_engine_class.new(ac)

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
  # launch_thing is a process definition or a launch item
  #
  def assert_trace (launch_thing, expected_trace, opts={})

    fei = @engine.launch(launch_thing, opts[:launch_opts] || {})

    wait(fei, opts)

    yield(engine) if block_given?

    check_remaining_expressions(opts)

    assert_equal(expected_trace, @tracer.to_s) if expected_trace
  end

  protected

  def log_level_to_debug

    $OWFE_LOG.level = Logger::DEBUG
  end

  def wait (fei, opts)

    #opts[:wait] ?
    #  @engine.wait_for(fei) :
    #  sleep(opts[:after] || 0.350)

    Thread.pass
    return if @terminated_processes.include?(fei.wfid)
    @engine.wait_for(fei)
  end

  def check_remaining_expressions (opts)

    assert_equal 1, @engine.get_expression_storage.size
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

