
#
# testing ruote
#
# Wed Sep 21 15:15:09 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtTakeAndDiscardAttributesTest < Test::Unit::TestCase
  include FunctionalBase

  def test_take

    @dashboard.register :alpha do |workitem|
      workitem.fields['a'] = 'A'
      workitem.fields['b'] = 'B'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      set 'f:x' => 'X'
      set 'f:y' => 'Y'
      alpha :take => 'a'
    end)

    r = @dashboard.wait_for(wfid)

    assert_equal %w[ a x y ], r['workitem']['fields'].keys.sort
  end

  def test_take_regex

    @dashboard.register :alpha do |workitem|
      workitem.fields['a'] = 'A'
      workitem.fields['aa'] = 'A'
      workitem.fields['b'] = 'B'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      set 'f:x' => 'X'
      set 'f:y' => 'Y'
      alpha :take => /^a/
    end)

    r = @dashboard.wait_for(wfid)

    assert_equal %w[ a aa x y ], r['workitem']['fields'].keys.sort
  end

  def test_discard

    @dashboard.register :alpha do |workitem|
      workitem.fields['a'] = 'A'
      workitem.fields['b'] = 'B'
      workitem.fields['c'] = 'C'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      set 'f:x' => 'X'
      set 'f:y' => 'Y'
      alpha :discard => [ 'a', 'b' ]
    end)

    r = @dashboard.wait_for(wfid)

    assert_equal %w[ __result__ c x y ], r['workitem']['fields'].keys.sort
  end

  def test_discard_true

    @dashboard.register :alpha do |workitem|
      workitem.fields['a'] = 'A'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      set 'f:x' => 'X'
      alpha :discard => true
    end)

    r = @dashboard.wait_for(wfid)

    assert_equal %w[ x ], r['workitem']['fields'].keys.sort
  end
end

