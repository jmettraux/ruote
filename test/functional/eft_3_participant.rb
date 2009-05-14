
#
# Testing Ruote (OpenWFEru)
#
# Wed May 13 11:14:08 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_no_name

    pdef = Ruote.process_definition do
      participant :ref => 'alpha'
    end

    @engine.register_participant :alpha do |workitem|
      @tracer << "alpha"
    end

    assert_trace pdef, 'alpha'
  end
end

