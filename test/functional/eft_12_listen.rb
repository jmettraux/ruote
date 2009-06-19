
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
          listen :to => 'alpha'
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
end

