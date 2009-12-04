
#
# Testing Ruote (OpenWFEru)
#
# Tue Jun 23 10:55:16 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtLaunchitemTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch

    pdef = Ruote.process_definition do
      alpha
    end

    fields = nil

    @engine.register_participant :alpha do |workitem|
      fields = workitem.fields
      @tracer << 'a'
      nil
    end

    #noisy

    wfid = @engine.launch(pdef, :fields => { 'a' => 0, 'b' => 1 })
    wait_for(wfid)

    assert_equal('a', @tracer.to_s)
    assert_equal({"a"=>0, "b"=>1, "params"=>{"ref"=>"alpha"}}, fields)
  end

  def test_launchitem

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        echo '${f:car}'
      end
    end

    li = Ruote::Launchitem.new(pdef, 'car' => 'benz')

    assert_trace(li, 'benz')
  end
end

