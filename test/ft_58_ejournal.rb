
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Fri Jun 29 23:12:53 JST 2007
#

require 'rubygems'

require 'openwfe/def'

require File.dirname(__FILE__) + '/flowtestbase'

require 'openwfe/engine/file_persisted_engine'
require 'openwfe/expool/errorjournal'



class FlowTest58 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end


  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      participant :alpha
      participant :nada
      participant :bravo
    end
  end

  def test_0

    ejournal = @engine.get_error_journal

    @engine.register_participant(:alpha) do |wi|
      @tracer << "alpha\n"
    end

    li = OpenWFE::LaunchItem.new Test0
    fei = launch li

    sleep 0.300

    assert File.exist?("work/ejournal/#{fei.parent_wfid}.ejournal") \
      if @engine.is_a?(OpenWFE::FilePersistedEngine)

    errors = ejournal.get_error_log fei

    #require 'pp'; pp ejournal
    #puts "/// error journal of class #{ejournal.class.name}"

    assert_equal 1, errors.length

    assert ejournal.has_errors?(fei)
    assert ejournal.has_errors?(fei.wfid)

    assert_equal 1, ejournal.get_error_logs.size
    assert_equal fei.wfid, ejournal.get_error_logs.keys.first

    # OK, let's fix the root and replay

    @engine.register_participant(:nada) do |wi|
      @tracer << "nada\n"
    end
    @engine.register_participant(:bravo) do |wi|
      @tracer << "bravo\n"
    end

    # fix done

    assert_equal "alpha", @tracer.to_s

    @engine.replay_at_error errors.first

    sleep 0.300

    assert_equal "alpha\nnada\nbravo", @tracer.to_s

    errors = ejournal.get_error_log fei

    assert_equal 0, errors.length

    assert ( ! ejournal.has_errors?(fei))
  end

  #
  # TEST 1

  # Testing that the changes to the workitem are taken into account

  class Test1 < OpenWFE::ProcessDefinition
    sequence do
      participant :nada
      _print "it's ${f:weather}"
    end
  end

  def test_1

    ejournal = @engine.get_error_journal

    li = OpenWFE::LaunchItem.new Test1
    li.weather = "sunny"

    fei = launch li

    sleep 0.300

    errors = ejournal.get_error_log fei

    #require 'pp'; pp ejournal
    #puts "/// error journal of class #{ejournal.class.name}"

    assert_equal 1, errors.length

    assert ejournal.has_errors?(fei)
    assert ejournal.has_errors?(fei.wfid)

    #
    # fix

    @engine.register_participant :nada do
      # do nothing
    end

    #
    # replay

    error = errors.first

    assert_equal "sunny", error.workitem.weather

    error.workitem.weather = "rainy"

    @engine.replay_at_error error

    sleep 0.300

    assert_trace "it's rainy"
  end

end

