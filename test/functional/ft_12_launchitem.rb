
#
# Testing Ruote (OpenWFEru)
#
# Tue Jun 23 10:55:16 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtLaunchitemTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launchitem

    pdef = Ruote.process_definition do
      alpha
    end

    fields = nil

    @engine.register_participant :alpha do |workitem|
      fields = workitem.fields
      @tracer << 'a'
    end

    #noisy

    wfid = @engine.launch(pdef, :workitem => { 'a' => 0, 'b' => 1 })
    wait_for(wfid)

    assert_equal('a', @tracer.to_s)
    assert_equal({ 'a' => 0, 'b' => 1 }, fields)
  end
end

