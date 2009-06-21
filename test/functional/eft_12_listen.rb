
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

  def test_upon

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          listen :to => '^al.*'
          bravo
        end
        sequence do
          listen :to => '^al.*', :upon => 'reply', :merge => true
          bravo
        end
        sequence do
          alpha
        end
      end
    end

    #noisy

    @engine.register_participant :alpha do |workitem|
      @tracer << "alpha\n"
      workitem.fields['seen'] = 'yes'
    end
    @engine.register_participant :bravo do |workitem|
      @tracer << "bravo:#{workitem.fields['seen']}\n"
    end

    assert_trace(pdef, %w[ alpha bravo: bravo:yes ], :sleep => 1.0)
  end

  def test_merge_override

    pdef = Ruote.process_definition do
      set :f => 'name', :val => 'Kilroy'
      set :f => 'other', :val => 'nothing'
      concurrence do
        sequence do
          listen :to => '^al.*', :merge => 'override'
          bravo
        end
        sequence do
          alpha
        end
      end
    end

    #noisy

    @engine.register_participant :alpha do |wi|
      @tracer << "alpha\n"
      wi.fields['name'] = 'William Mandella'
    end
    @engine.register_participant :bravo do |wi|
      @tracer << "name:#{wi.fields['name']} "
      @tracer << "other:#{wi.fields['other']}\n"
    end

    assert_trace(pdef, "alpha\nname:William Mandella other:nothing")
  end
end

