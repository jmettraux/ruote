
#
# Testing Ruote (OpenWFEru)
#
# Tue Jun  2 18:48:02 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtOnErrorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_on_error

    pdef = Ruote.process_definition do
      sequence :on_error => 'catcher' do
        nada
      end
    end

    @engine.register_participant :catcher do
      @tracer << "caught\n"
    end

    #noisy

    assert_trace(pdef, 'caught')

    assert_equal 1, logger.log.select { |e| e['action'] == 'fail' }.size
  end

  def test_on_error_neutralization

    pdef = Ruote.process_definition do
      sequence :on_error => 'catcher' do
        sequence :on_error => '' do
          nada
        end
      end
    end

    @engine.register_participant :catcher do
      @tracer << "caught\n"
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)
    ps = @engine.process(wfid)

    assert_equal(1, ps.errors.size)
  end

  def test_on_error_redo

    pdef = Ruote.process_definition do
      sequence :on_error => :redo do
        troublemaker
      end
    end

    hits = 0

    @engine.register_participant :troublemaker do
      hits += 1
      @tracer << "#{hits.to_s}\n"
      raise 'Houston, we have a problem !' if hits == 1
      @tracer << 'done.'
    end

    #noisy

    assert_trace(pdef, %w[ 1 2 done. ])
  end

  def test_on_error_undo

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        sequence :on_error => :undo do
          echo 'b'
          nemo
          echo 'c'
        end
        echo 'd'
      end
    end

    #noisy

    wfid = assert_trace(pdef, %w[ a b d ])

    assert_nil @engine.process(wfid)
  end

  def test_missing_handler_triggers_regular_error

    pdef = Ruote.process_definition :on_error => 'failpath' do
      nemo
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)
    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    assert_equal 1, logger.log.select { |e| e['action'] == 'error_intercepted' }.size
  end

  def test_on_error_at_process_level

    pdef = Ruote.process_definition :on_error => 'failpath' do
      nemo
      define :failpath do
        echo 'failed.'
      end
    end

    #noisy

    assert_trace(pdef, 'failed.')
  end

  def test_with_concurrence

    pdef = Ruote.process_definition do
      sequence do
        concurrence :on_error => 'emil' do
          alpha
          error 'nada0'
          error 'nada1'
        end
        echo 'done.'
      end
    end

    acount = 0
    ecount = 0
    @engine.register_participant(:alpha) { |wi| acount += 1 }
    @engine.register_participant(:emil) { |wi| ecount += 1 }

    #noisy

    assert_trace pdef, 'done.'
    assert_equal 1, acount
    assert_equal 1, ecount
  end
end

