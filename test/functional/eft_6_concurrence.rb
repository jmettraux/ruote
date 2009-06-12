
#
# Testing Ruote (OpenWFEru)
#
# Thu Jun 11 15:24:47 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class EftConcurrenceTest < Test::Unit::TestCase
  include FunctionalBase

  def test_basic

    pdef = Ruote.process_definition do
      concurrence do
        alpha
        alpha
      end
    end

    @engine.register_participant :alpha do
      @tracer << "alpha\n"
    end

    #noisy

    assert_trace pdef, %w[ alpha alpha ]
  end

  # helper
  #
  def run_concurrence (concurrence_attributes, noise)

    pdef = Ruote.process_definition do
      sequence do
        concurrence(concurrence_attributes) do
          alpha
          alpha
        end
      end
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    noisy if noise

    wfid = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)

    2.times do
      wi = alpha.first
      wi.fields['seen'] = wi.fei.expid
      alpha.reply(wi)
    end

    wait_for(:alpha)

    wi = alpha.first

    ps = @engine.process_status(wi.fei.wfid)
    assert_equal %w[ 0 0_1 ], ps.expressions.collect { |e| e.fei.expid }.sort

    wi
  end

  def test_default_merge

    wi = run_concurrence({}, false)

    assert_equal '0_1', wi.fei.expid
    assert_equal '0_0_0_0', wi.fields['seen']
  end

  def test_merge_last

    wi = run_concurrence({ :merge => :last }, false)

    assert_equal '0_1', wi.fei.expid
    assert_equal '0_0_0_1', wi.fields['seen']
  end

  def test_concurrence_merge_type_isolate

    wi = run_concurrence({ :merge_type => :isolate }, false)

    assert_equal(
      {1=>{"seen"=>"0_0_0_1"}, 0=>{"seen"=>"0_0_0_0"}},
      wi.fields)
  end

  # helper
  #
  def run_test_count (remaining, noise)

    pdef = Ruote.process_definition do
      concurrence :count => 1, :remaining => remaining do
        alpha
        bravo
      end
    end

    @alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    @bravo = @engine.register_participant :bravo, Ruote::HashParticipant

    noisy if noise

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    @alpha.reply(@alpha.first)

    wait_for(wfid)

    wfid
  end

  def test_count

    wfid = run_test_count('cancel', false)

    assert_equal 1, logger.log.select { |e| e[1] == :cancel }.size

    assert_equal 0, @alpha.size
    assert_equal 0, @bravo.size
  end

  def test_count_remaining_forget

    wfid = run_test_count('forget', false)

    assert_equal 1, logger.log.select { |e| e[1] == :forgotten }.size

    assert_equal 0, @alpha.size
    assert_equal 1, @bravo.size

    assert_equal 1, @engine.expstorage.size
    assert_not_nil @engine.process_status(wfid)

    @bravo.reply(@bravo.first)

    sleep 0.007
  end
end

