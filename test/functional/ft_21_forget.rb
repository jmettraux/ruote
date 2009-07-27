
#
# Testing Ruote (OpenWFEru)
#
# Mon Jul 27 09:17:51 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtForgetTest < Test::Unit::TestCase
  include FunctionalBase

  def test_basic

    pdef = Ruote.process_definition do
      sequence do
        alpha :forget => true
        alpha
      end
    end

    @engine.register_participant :alpha do
      @tracer << "alpha\n"
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)
    wait_for(wfid)

    assert_equal %w[ alpha alpha ].join("\n"), @tracer.to_s

    assert_equal 2, logger.log.select { |e| e[1] == :terminated }.size
      # process ended 2 times
  end
end

