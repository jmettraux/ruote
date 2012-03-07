
#
# testing ruote
#
# Wed Jun 10 17:41:23 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtSubprocessesTest < Test::Unit::TestCase
  include FunctionalBase

  def test_subprocess_tree_lookup

    pdef = Ruote.process_definition do
      define 'sub0' do
        bravo
        echo 'result : ${v:nada}'
      end
      sequence do
        bravo
        sub0
      end
    end

    bravo = @dashboard.register_participant :bravo, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(:bravo)

    fexp = Ruote::Exp::FlowExpression.fetch(
      @dashboard.context, bravo.first.fei.to_h)

    assert_equal(
      [ '0_0',
        ['define', {'sub0'=>nil}, [['bravo', {}, []], ['echo', {'result : ${v:nada}'=>nil}, []]]] ],
      fexp.lookup_variable('sub0'))

    bravo.proceed(bravo.first)
    wait_for(:bravo)

    fexp = Ruote::Exp::FlowExpression.fetch(
      @dashboard.context, bravo.first.fei.to_h)

    assert_equal(
      ['define', {'sub0'=>nil}, [['bravo', {}, []], ['echo', {'result : ${v:nada}'=>nil}, []]]],
      fexp.parent.tree)

    #logger.log.each { |e| puts e['action'] }
    assert_equal 2, logger.log.select { |e| e['action'] == 'launch' }.size
  end

  def test_subid

    pdef = Ruote.process_definition do
      sequence do
        sub0 :forget => true
        sub0 :forget => true
      end
      define 'sub0' do
        sub1 :forget => true
      end
      define 'sub1' do
        alpha
      end
    end

    @dashboard.context.stash[:wfids] = []

    @dashboard.register_participant :alpha do |workitem|
      stash[:wfids] << workitem.fei.subid
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)
    wait_for(6)

    assert_equal 2, @dashboard.context.stash[:wfids].size
    assert_equal 2, @dashboard.context.stash[:wfids].sort.uniq.size
  end

  def test_cancel_and_subprocess

    pdef = Ruote.process_definition do
      sequence do
        sub0
      end
      define 'sub0' do
        alpha
      end
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, alpha.size

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 0, alpha.size
  end

  def test_cancel_and_engine_variable_subprocess

    pdef = Ruote.process_definition do
      sequence do
        sub0
      end
    end

    @dashboard.variables['sub0'] = Ruote.process_definition do
      alpha
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, alpha.size

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 0, alpha.size
  end

  # testing noisy and process definition output...
  #
  def test_sub_subprocess

    pdef = Ruote.process_definition do
      sequence do
        sub0
      end
      define 'sub0' do
        echo 'a'
        sub1
        define 'sub1' do
          echo 'b'
        end
      end
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ a b ], @tracer.to_a
  end
end

