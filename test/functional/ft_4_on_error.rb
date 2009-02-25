
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Nov 27 16:30:23 JST 2008
#

require File.dirname(__FILE__) + '/base'


class FtOnErrorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_on_error_undo

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        echo '0'
        sequence :on_error => :undo do
          alpha
          echo '1'
        end
        echo '2'
      end
    end

    @engine.register_participant(:alpha) do |workitem|
      raise 'Houston, we have a problem !'
    end

    assert_trace pdef, "0\n2"
  end

  def test_on_error_failpath

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        echo '0'
        sequence :on_error => 'fail_path' do
          alpha
          echo '1'
        end
        echo '2'
      end
      define 'fail_path' do
        echo 'failed'
      end
    end

    @engine.register_participant(:alpha) do |workitem|
      raise 'Houston, we have a problem !'
    end

    assert_trace pdef, "0\nfailed\n2"
  end

  def test_on_error_neutralization

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        echo '0'
        sequence :on_error => 'fail_path' do
          echo '1'
          alpha :on_error => ''
          echo '2'
        end
        echo '3'
      end
      define 'fail_path' do
        echo 'failed'
      end
    end

    @engine.register_participant(:alpha) do |workitem|
      raise 'Houston, we have a problem !'
    end

    fei = @engine.launch(pdef)

    sleep 0.350

    ps = @engine.process_status(fei)

    assert_equal 1, ps.errors.size

    purge_engine
  end

  def test_on_error_redo

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        echo '0'
        sequence :on_error => :redo do
          echo '1'
          alpha
          echo '2'
        end
        echo '3'
      end
    end

    hits = 0

    @engine.register_participant(:alpha) do |workitem|
      hits += 1
      raise 'Houston, we have a problem !' if hits == 1
    end

    assert_trace pdef, %w{ 0 1 1 2 3 }.join("\n")
  end

  def test_on_error_nested_rescue

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence :on_error => 'parent_rescue' do
        echo '0'
        sequence :on_error => 'rescue' do
          echo '1'
          alpha
          echo '2'
        end
      end
      define 'rescue' do
        sequence do
          echo 'rescue'
          bravo
          echo '3'
        end
      end
      define 'parent_rescue' do
        echo 'parent_rescue'
      end
    end

    @engine.register_participant(:alpha) do |workitem|
      raise 'Houston, we have a problem !'
    end
    @engine.register_participant(:bravo) do |workitem|
      raise 'Houston, we have had a problem.'
    end

    assert_trace pdef, %w{ 0 1 rescue parent_rescue }.join("\n")
  end

  def test_on_error_at_process_level

    pdef = OpenWFE.process_definition :name => 'test', :on_error => 'rescue' do
      sequence do
        echo '0'
        alpha
        echo '1'
      end
      define 'rescue' do
        echo 'r'
      end
    end

    @engine.register_participant(:alpha) do |workitem|
      raise 'Houston, we have a problem !'
    end

    fei = @engine.launch(pdef)

    sleep 0.350

    assert_equal "0\nr", @tracer.to_s
  end

  def test_on_error_and_raise

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence :on_error => 'fail_path' do
        echo 'a'
        error 'failing'
        echo 'b'
      end
      define 'fail_path' do
        echo 'failed.'
      end
    end

    assert_trace pdef, "a\nfailed."
  end

  def test_on_error_failpath_and_variables

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence :on_error => 'fail_path' do
        set :var => 'var0', :val => 'val0'
        error 'fail'
      end
      define 'fail_path' do
        echo 'var0:${var0}'
      end
    end

    assert_trace pdef, 'var0:val0'
  end

  def test_on_error_failpath_and_variables_at_the_process_level

    pdef = OpenWFE.process_definition :name => 't', :on_error => 'fail_path' do
      sequence do
        set :var => 'var0', :val => 'val0'
        error 'fail'
      end
      define 'fail_path' do
        echo 'var0:${var0}'
      end
    end

    assert_trace(pdef, 'var0:val0') { sleep 0.100 }
      # the sleep 0.100 is only useful for --fs -C
  end

end

