
#
# testing ruote
#
# Sun Jun 14 13:33:17 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftForgetTest < Test::Unit::TestCase
  include FunctionalBase

  def test_basic

    pdef = Ruote.process_definition do
      sequence do
        forget do
          alpha
        end
        alpha
      end
    end

    @dashboard.register_participant :alpha do
      tracer << "alpha\n"
    end

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)
    wait_for(wfid)
    wait_for(wfid)

    assert_equal "alpha\nalpha", @tracer.to_s

    assert_equal 1, logger.log.select { |e| e['action'] == 'ceased' }.size
    assert_equal 1, logger.log.select { |e| e['action'] == 'terminated' }.size
  end

  def test_multi

    pdef = Ruote.define do
      forget do
        alpha
        bravo
      end
      charly
    end

    @dashboard.register_participant '.+' do |wi|
      context.tracer << wi.participant_name + "\n"
    end

    wfid = @dashboard.launch(pdef)

    3.times { @dashboard.wait_for('dispatched') }

    assert_equal %w[ alpha bravo charly ], @tracer.to_a.sort
  end
end

