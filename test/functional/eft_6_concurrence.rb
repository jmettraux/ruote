
#
# Testing Ruote (OpenWFEru)
#
# Thu Jun 11 15:24:47 JST 2009
#

require File.dirname(__FILE__) + '/base'


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

    noisy

    assert_trace pdef, %w[ alpha alpha ]
  end
end

