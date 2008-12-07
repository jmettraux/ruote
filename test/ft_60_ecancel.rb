
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Jul  9 10:25:18 JST 2007
#

require 'rubygems'

require 'openwfe/def'
require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest60 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class TestDefinition0 < OpenWFE::ProcessDefinition
    sequence do
      _print 'a'
      sequence do
        _print 'b.0'
        _sleep '1s'
        _print 'b.1'
      end
      _print 'c'
    end
  end

  def test_0

    #log_level_to_debug

    fei = launch TestDefinition0

    sleep 0.350

    #puts
    #puts @engine.get_process_stack(fei.wfid)
    #puts

    fei.expression_id = '0.0.1'
    fei.expression_name = 'sequence'
    @engine.cancel_expression fei

    sleep 0.350

    assert_equal "a\nb.0\nc", @tracer.to_s

    assert_equal 0, @engine.process_stack(fei.wfid).size
    assert_equal 1, @engine.get_expression_storage.size
  end

  def _test_1
    #
    # as the sequence expression doesn't load up all its children
    # at once (before apply) this test case became invalid

    #log_level_to_debug

    fei = launch TestDefinition0

    sleep 0.350

    #puts
    #puts @engine.get_process_stack(fei.wfid)
    #puts

    fei.expression_id = '0.0.1.2'
    fei.expression_name = 'print'
    @engine.cancel_expression fei

    #@engine.wait_for(fei.wfid)
    wait_for fei

    assert_equal "a\nb.0\nc", @tracer.to_s

    assert_equal 0, @engine.process_stack(fei.wfid).size
    assert_equal 1, @engine.get_expression_storage.size
  end

  def test_2

    #log_level_to_debug

    fei = launch TestDefinition0

    sleep 0.350

    fei.expression_id = '0'
    fei.expression_name = 'process-definition'
    @engine.cancel_expression fei

    sleep 0.350
    #puts @engine.get_error_journal.get_error_log(fei.wfid).to_s

    assert_equal "a\nb.0", @tracer.to_s

    assert_equal 0, @engine.process_stack(fei.wfid).size
    assert_equal 1, @engine.get_expression_storage.size
  end

  def test_2b

    #log_level_to_debug

    fei = launch <<-EOS
      class Test2b < OpenWFE::ProcessDefinition
        nada
      end
    EOS

    # will result in an error
    # testing against bug
    # http://rubyforge.org/tracker/index.php?func=detail&aid=19607&group_id=2609&atid=10023

    sleep 0.350

    fei.expression_id = '0'
    fei.expression_name = 'process-definition'
    @engine.cancel_expression fei

    sleep 0.350
    #puts @engine.get_error_journal.get_error_log(fei.wfid).to_s

    assert_equal '', @tracer.to_s

    assert_equal 0, @engine.process_stack(fei.wfid).size
    assert_equal 1, @engine.get_expression_storage.size
  end

  def test_3

    #log_level_to_debug

    fei = launch TestDefinition0

    sleep 0.350

    fei.expression_id = '0.0'
    fei.expression_name = 'sequence'
    @engine.cancel_expression fei

    wait_for fei

    #sleep 0.350
    #puts @engine.get_error_journal.get_error_log(fei.wfid).to_s

    assert_equal "a\nb.0", @tracer.to_s

    assert_equal 0, @engine.process_stack(fei.wfid).size
    assert_equal 1, @engine.get_expression_storage.size
  end

end

