
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Since Mon Oct  9 22:19:44 JST 2006
#

require File.dirname(__FILE__) + '/base'


class FtOnCancelTest < Test::Unit::TestCase
  include FunctionalBase

  def test_on_cancel_participant

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence :on_cancel => 'decommission' do
        alpha
      end
    end

    @engine.register_participant(:alpha, OpenWFE::NullParticipant)
      # receives workitems, discards them, doesn't reply to the engine

    @engine.register_participant(:decommission) do |workitem|
      @tracer << "#{workitem.fei.wfid} decom\n"
    end

    fei = @engine.launch(pdef)

    sleep 0.350

    assert_equal '', @tracer.to_s

    ps = @engine.process_status(fei)

    assert_equal 1, ps.expressions.size
    assert_equal 'alpha', ps.expressions.first.fei.expname

    @engine.cancel_process(fei)

    sleep 0.350

    assert_equal "#{fei.wfid}.0 decom", @tracer.to_s

    assert_nil @engine.process_status(fei)
  end

  def test_on_cancel_subprocess

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence :on_cancel => 'decommission' do
        alpha
      end
      process_definition :name => 'decommission' do
        sequence do
          echo 'decommission...'
          echo 'decommissioned.'
        end
      end
    end

    @engine.register_participant(:alpha, OpenWFE::NullParticipant)
      # receives workitems, discards them, doesn't reply to the engine

    fei = @engine.launch(pdef)

    sleep 0.350

    assert_equal '', @tracer.to_s

    @engine.cancel_process(fei)

    sleep 0.350

    assert_equal "decommission...\ndecommissioned.", @tracer.to_s

    assert_nil @engine.process_status(fei)
  end

  def test_on_cancel_via_cancel_process_expression

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence :on_cancel => 'decommission' do
        echo 'a'
        cancel_process
        echo 'b'
      end
      process_definition :name => 'decommission' do
        sequence do
          echo 'y'
          echo 'z'
        end
      end
    end

    fei = @engine.launch(pdef)

    sleep 0.350

    assert_equal "a\ny\nz", @tracer.to_s

    assert_nil @engine.process_status(fei)
  end

  def test_on_cancel_and_variables

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence :on_cancel => 'decommission' do
        echo 'a'
        set :var => 'v0', :val => 'z'
        cancel_process
        echo 'b'
      end
      process_definition :name => 'decommission' do
        sequence do
          echo '${v0}'
        end
      end
    end

    fei = @engine.launch(pdef)

    sleep 0.350

    assert_equal "a\nz", @tracer.to_s

    assert_nil @engine.process_status(fei)
  end

  def test_on_cancel_and_undo

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence :on_cancel => 'decom', :tag => 'seq' do
        echo 'a'
        undo 'seq'
        echo 'b'
      end
      process_definition :name => 'decom' do
        echo 'd'
      end
    end

    assert_trace pdef, "a\nd"
  end

  def test_on_cancel_and_redo

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence :on_cancel => 'decom', :tag => 'seq' do
        echo 'a'
        _redo 'seq'
        echo 'b'
      end
      process_definition :name => 'decom' do
        echo 'd'
      end
    end

    fei = @engine.launch(pdef)

    sleep 0.350

    assert_equal %w{ a d a b }.join("\n"), @tracer.to_s

    assert_nil @engine.process_status(fei)
  end
end

