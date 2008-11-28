
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Nov 27 16:30:23 JST 2008
#

require 'flowtestbase'


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
end

