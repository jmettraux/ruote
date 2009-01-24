
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Sep 20 23:40:10 JST 2008
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/engine'


module FunctionalBase

  def setup

    ENV['TOKYO_CABINET_LIB'] = File.expand_path(
      '~/tmp/tokyo-cabinet/libtokyocabinet.dylib'
    ) if ARGV.include?('--tc-latest')

    engine_class = if $ruote_engine_class
      $ruote_engine_class
    else
      if ARGV.include?('--fp')
        require 'openwfe/engine/file_persisted_engine'
        OpenWFE::FilePersistedEngine
      elsif ARGV.include?('--cfp')
        require 'openwfe/engine/file_persisted_engine'
        OpenWFE::CachedFilePersistedEngine
      elsif ARGV.include?('--tp')
        require 'openwfe/engine/tc_engine'
        OpenWFE::TokyoPersistedEngine
      else
        OpenWFE::Engine
      end
    end

    @tracer = Tracer.new

    ac = {}
    ac['__tracer'] = @tracer
    ac[:definition_in_launchitem_allowed] = true

    @engine = engine_class.new(ac)

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

