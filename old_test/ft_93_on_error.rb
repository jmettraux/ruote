
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Nov 27 16:30:23 JST 2008
#

require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest93 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  # a block with on_error => 'undo' (or :undo)
  # will simply get undone in case of error

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      _print '0'
      sequence :on_error => :undo do
        alpha
        _print '1'
      end
      _print '2'
    end
  end

  def test_0

    @engine.register_participant :alpha do |fexp, workitem|
      raise 'houston, we have a problem'
    end

    dotest Test0, "0\n2"
  end

  #
  # TEST 1

  class Test1 < OpenWFE::ProcessDefinition
    sequence do
      _print '0'
      sequence :on_error => 'fail_path' do
        alpha
        _print '1'
      end
      _print '2'
    end
    define 'fail_path' do
      _print 'failed'
    end
  end

  def test_1

    #log_level_to_debug

    @engine.register_participant :alpha do |fexp, workitem|
      raise 'houston, we have a problem'
    end

    dotest Test1, "0\nfailed\n2"
  end

  #
  # TEST 2

  # :on_error => '' will neutralize error handling for its block

  class Test2 < OpenWFE::ProcessDefinition
    sequence do
      _print '0'
      sequence :on_error => 'fail_path' do
        _print '1'
        alpha :on_error => ''
        _print '2'
      end
      _print '3'
    end
    define 'fail_path' do
      _print 'failed'
    end
  end

  def test_2

    #log_level_to_debug

    @engine.register_participant :alpha do |fexp, workitem|
      raise 'houston, we have a problem'
    end

    fei = @engine.launch Test2

    sleep 0.450

    assert_equal "0\n1", @tracer.to_s

    ps = @engine.process_status(fei)
    assert_equal 1, ps.errors.size

    purge_engine
  end

  #
  # TEST 3

  class Test3 < OpenWFE::ProcessDefinition
    sequence do
      _print '0'
      sequence :on_error => 'redo' do
        _print '1'
        alpha
        _print '2'
      end
      _print '3'
    end
  end

  def test_3

    hits = 0

    @engine.register_participant :alpha do |fexp, workitem|
      hits += 1
      raise 'houston, we have a problem' if hits == 1
      # else don't raise an error and let the flow resume...
    end

    dotest Test3, %w{ 0 1 1 2 3 }.join("\n")
  end

  #
  # TEST 4

  class Test4 < OpenWFE::ProcessDefinition
    sequence :on_error => 'parent_rescue' do
      _print '0'
      sequence :on_error => 'rescue' do
        _print '1'
        alpha
        _print '2'
      end
    end
    define 'rescue' do
      sequence do
        _print 'rescue'
        bravo
        _print '3'
      end
    end
    define 'parent_rescue' do
      _print 'parent_rescue'
    end
  end

  def test_4

    #log_level_to_debug

    @engine.register_participant :alpha do |fexp, workitem|
      raise 'houston, we have a problem'
    end
    @engine.register_participant :bravo do |fexp, workitem|
      raise "houston, we've had a problem"
    end

    dotest Test4, %w{ 0 1 rescue parent_rescue }.join("\n")
  end

  #
  # TEST 5

  class Test5 < OpenWFE::ProcessDefinition
    process_definition(
      :name => 'a', :revision => '0', :on_error => :emergency
    ) do
      sequence do
        _print '0'
        alpha
        _print '1'
      end
      define 'emergency' do
        _print 'e'
      end
    end
  end
  #Test5 = %{
  #  <process-definition name="a" revision="0" on-error="emergency">
  #    <sequence>
  #      <print>0</print>
  #      <alpha />
  #      <print>1</print>
  #    </sequence>
  #    <process-definition name="emergency">
  #      <print>e</print>
  #    </process-definition>
  #  </process-definition>
  #}

  def test_5

    @engine.register_participant :alpha do |fexp, workitem|
      raise 'houston, we have a problem'
    end

    @engine.launch Test5
    sleep 0.350
      # have to use launch+sleep as the on_error is on the process itself
      # and dotest detects the end of it at the moment of the on_error handling

    assert_equal "0\ne", @tracer.to_s
    assert_equal 1, @engine.get_expression_storage.size
  end
end

