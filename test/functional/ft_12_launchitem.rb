
#
# testing ruote
#
# Tue Jun 23 10:55:16 JST 2009
#

#require 'rufus-json/automatic'
require File.expand_path('../base', __FILE__)


class FtLaunchitemTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch

    pdef = Ruote.process_definition do
      alpha
    end

    @dashboard.register_participant :alpha do |workitem|
      stash[:fields] = workitem.fields
      tracer << 'a'
      nil
    end

    wfid = @dashboard.launch(pdef, 'a' => 0, 'b' => 1)
    wait_for(wfid)

    assert_equal('a', @tracer.to_s)

    @dashboard.context.stash[:fields].delete('__result__')

    assert_not_nil(
      @dashboard.context.stash[:fields].delete('dispatched_at'))

    assert_equal(
      {"a"=>0, "b"=>1, "params"=>{"ref"=>"alpha"}},
      @dashboard.context.stash[:fields])
  end

  # Warning: this test requires rufus-json to have a backend ready.
  #
  def test_launch_and_variables_with_symbol_keys

    pdef = Ruote.define do
      echo '${f} / ${v:v}'
    end

    wfid = @dashboard.launch(pdef, { :f => 'x' }, { :v => 'y' })
    wait_for(wfid)

    assert_equal 'x / y', @tracer.to_s
  end
end

