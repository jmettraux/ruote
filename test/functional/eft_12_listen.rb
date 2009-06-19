
#
# Testing Ruote (OpenWFEru)
#
# Fri Jun 19 15:26:33 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftListenTest < Test::Unit::TestCase
  include FunctionalBase

  def test_listen

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          echo '0'
          listen :to => '^al.*'
          echo '1'
        end
        sequence do
          alpha
        end
      end
    end

    #noisy

    @engine.register_participant :alpha do
      @tracer << "alpha\n"
    end

    assert_trace(pdef, %w[ 0 alpha 1 ])
  end

  def test_listen_with_child

    pdef = Ruote.process_definition do
      concurrence do
        listen :to => '^al.*' do
          bravo
        end
        sequence do
          alpha
          alpha
        end
      end
    end

    #noisy

    @engine.register_participant :alpha do
      @tracer << "a\n"
    end
    @engine.register_participant :bravo do |workitem|
      @tracer << workitem.fei.wfid
      @tracer << "\n"
    end

    wfid = @engine.launch(pdef)

    sleep 1.0

    assert_equal "a\na\n#{wfid}_0\n#{wfid}_1", @tracer.to_s

    ps = @engine.process_status(wfid)

    assert_equal 3, ps.expressions.size
    assert_equal 0, ps.errors.size
  end
end

