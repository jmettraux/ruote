
#
# testing ruote
#
# Fri May 13 14:12:52 JST 2011
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/fei'
require 'ruote/merge'
require 'ruote/extract'
require 'ruote/exp/flow_expression'
require 'ruote/exp/fe_concurrence'


class MergeTest < Test::Unit::TestCase

  class Merger < Ruote::Exp::ConcurrenceExpression
    def initialize
    end
    def tree
      [ 'nada', {}, [] ]
    end
    public :merge_workitems
  end

  def new_workitem(expid, fields)

    {
      'fei' => {
        'engine' => 'e', 'wfid' => '12', 'subid' => '34', 'expid' => expid
      },
      'fields' => fields
    }
  end

  def new_workitems

    [
      new_workitem('0_0', 'a' => 0, 'b' => -1),
      new_workitem('0_1', 'a' => 1)
    ]
  end

  def test_override

    assert_equal(
      { 'a' => 1 },
      Merger.new.merge_workitems(new_workitems, 'override')['fields'])
    assert_equal(
      { 'a' => 0, 'b' => -1 },
      Merger.new.merge_workitems(new_workitems.reverse, 'override')['fields'])
  end

  def test_mix

    assert_equal(
      { 'a' => 1, 'b' => -1 },
      Merger.new.merge_workitems(new_workitems, 'mix')['fields'])
    assert_equal(
      { 'a' => 0, 'b' => -1 },
      Merger.new.merge_workitems(new_workitems.reverse, 'mix')['fields'])
  end

  def test_isolate

    assert_equal(
      { '0' => { 'a' => 0, 'b' => -1 }, '1' => { 'a' => 1 } },
      Merger.new.merge_workitems(new_workitems, 'isolate')['fields'])
    assert_equal(
      { '1' => { 'a' => 1 }, '0' => { 'a' => 0, 'b' => -1 } },
      Merger.new.merge_workitems(new_workitems.reverse, 'isolate')['fields'])
  end

  def test_stack

    assert_equal(
      { 'stack' => [ { 'a' => 0, 'b' => -1 }, { 'a' => 1 } ] },
      Merger.new.merge_workitems(new_workitems, 'stack')['fields'])
    assert_equal(
      { 'stack' => [ { 'a' => 1 }, { 'a' => 0, 'b' => -1 } ] },
      Merger.new.merge_workitems(new_workitems.reverse, 'stack')['fields'])
  end

  def test_unknown

    assert_equal(
      { 'a' => 0, 'b' => -1 },
      Merger.new.merge_workitems(new_workitems, '???')['fields'])
    assert_equal(
      { 'a' => 1 },
      Merger.new.merge_workitems(new_workitems.reverse, '???')['fields'])
  end

  def test_union

    workitems = [
      new_workitem(
        '0_0', 'a' => 0, 'b' => [ 'x', 'y' ], 'c' => { 'aa' => 'bb' }),
      new_workitem(
        '0_1', 'a' => 1, 'b' => [ 'y', 'z' ], 'c' => { 'cc' => 'dd' })
    ]

    assert_equal(
      {
        'a' => 1,
        'b' => [ 'x', 'y', 'z' ],
        'c' => { 'aa' => 'bb', 'cc' => 'dd' }
      },
      Merger.new.merge_workitems(workitems, 'union')['fields'])
  end

  def test_concat

    workitems = [
      new_workitem(
        '0_0', 'a' => 0, 'b' => [ 'x', 'y' ], 'c' => { 'aa' => 'bb' }),
      new_workitem(
        '0_1', 'a' => 1, 'b' => [ 'y', 'z' ], 'c' => { 'cc' => 'dd' })
    ]

    assert_equal(
      {
        'a' => 1,
        'b' => [ 'x', 'y', 'y', 'z' ],
        'c' => { 'aa' => 'bb', 'cc' => 'dd' }
      },
      Merger.new.merge_workitems(workitems, 'concat')['fields'])
  end

  def test_deep

    workitems = [
      new_workitem(
        '0_0',
        'a' => 0,
        'b' => [ 'x', 'y' ],
        'c' => { 'aa' => 'bb', 'cc' => { 'a' => 'b' } }),
      new_workitem(
        '0_1',
        'a' => 1,
        'b' => [ 'y', 'z' ],
        'c' => { 'dd' => 'ee', 'cc' => { 'c' => 'd' } })
    ]

    assert_equal(
      {
        'a' => 1,
        'b' => [ 'x', 'y', 'y', 'z' ],
        'c' => { 'aa' => 'bb', 'cc' => { 'a' => 'b', 'c' => 'd' }, 'dd' => 'ee' }
      },
      Merger.new.merge_workitems(workitems, 'deep')['fields'])
  end
end

