
#
# testing ruote
#
# Wed Sep 21 15:15:09 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtTakeAndDiscardAttributesTest < Test::Unit::TestCase
  include FunctionalBase

  def test_take

    @engine.register :alpha do |workitem|
      workitem.fields['a'] = 'A'
      workitem.fields['b'] = 'B'
    end

    #@engine.noisy = true

    wfid = @engine.launch(Ruote.define do
      set 'f:x' => 'X'
      set 'f:y' => 'Y'
      alpha :take => 'a'
    end)

    r = @engine.wait_for(wfid)

    assert_equal %w[ a x y ], r['workitem']['fields'].keys.sort
  end

  def test_take_regex

    @engine.register :alpha do |workitem|
      workitem.fields['a'] = 'A'
      workitem.fields['aa'] = 'A'
      workitem.fields['b'] = 'B'
    end

    #@engine.noisy = true

    wfid = @engine.launch(Ruote.define do
      set 'f:x' => 'X'
      set 'f:y' => 'Y'
      alpha :take => /^a/
    end)

    r = @engine.wait_for(wfid)

    assert_equal %w[ a aa x y ], r['workitem']['fields'].keys.sort
  end

  def test_discard

    @engine.register :alpha do |workitem|
      workitem.fields['a'] = 'A'
      workitem.fields['b'] = 'B'
      workitem.fields['c'] = 'C'
    end

    #@engine.noisy = true

    wfid = @engine.launch(Ruote.define do
      set 'f:x' => 'X'
      set 'f:y' => 'Y'
      alpha :discard => [ 'a', 'b' ]
    end)

    r = @engine.wait_for(wfid)

    assert_equal %w[ __result__ c x y ], r['workitem']['fields'].keys.sort
  end
end

