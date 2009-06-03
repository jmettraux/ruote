
#
# Testing Ruote (OpenWFEru)
#
# Tue Jun  2 18:48:02 JST 2009
#

require File.dirname(__FILE__) + '/base'


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

    assert_equal 1, logger.log.select { |e| e[1] == :on_error }.size
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
    wait
    ps = @engine.process_status(wfid)

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

    assert_trace(pdef, %w[ 1 2 done. ].join("\n"))
  end
end

