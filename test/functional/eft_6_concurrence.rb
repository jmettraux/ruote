
#
# Testing Ruote (OpenWFEru)
#
# Thu Jun 11 15:24:47 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class EftConcurrenceTest < Test::Unit::TestCase
  include FunctionalBase

  def test_concurrence

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

  # A helper method
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

    alpha.first
  end

  def test_concurrence_default_merge

    wi = run_concurrence({}, false)

    assert_equal '0_1', wi.fei.expid
    assert_equal '0_0_0_0', wi.fields['seen']
  end

  def test_concurrence_merge_last

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
end

