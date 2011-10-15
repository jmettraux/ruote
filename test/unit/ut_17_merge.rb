
#
# testing ruote
#
# Fri May 13 14:12:52 JST 2011
#

require File.expand_path('../../test_helper', __FILE__)

module Ruote; end
require 'ruote/exp/flow_expression'
require 'ruote/exp/merge'


class MergeTest < Test::Unit::TestCase

  class Merger < Ruote::Exp::FlowExpression
    include Ruote::Exp::MergeMixin
    def initialize
    end
    def tree
      [ 'nada', {}, [] ]
    end
  end

  def new_workitem(fields)

    { 'fields' => fields }
  end

  def new_workitems

    [
      new_workitem('a' => 0, 'b' => -1),
      new_workitem('a' => 1)
    ]
  end

  def test_override

    assert_equal(
      { 'fields' => { 'a' => 1 } },
      Merger.new.merge_workitems(new_workitems, 'override'))
    assert_equal(
      { 'fields' => { 'a' => 0, 'b' => -1 } },
      Merger.new.merge_workitems(new_workitems.reverse, 'override'))
  end

  def test_mix

    assert_equal(
      { 'fields' => { 'a' => 1, 'b' => -1 } },
      Merger.new.merge_workitems(new_workitems, 'mix'))
    assert_equal(
      { 'fields' => { 'a' => 0, 'b' => -1 } },
      Merger.new.merge_workitems(new_workitems.reverse, 'mix'))
  end

  def test_isolate

    assert_equal(
      { 'fields' => {
        '0' => { 'a' => 0, 'b' => -1 },
        '1' => { 'a' => 1 }
      } },
      Merger.new.merge_workitems(new_workitems, 'isolate'))
    assert_equal(
      { 'fields' => {
        '0' => { 'a' => 1 },
        '1' => { 'a' => 0, 'b' => -1 }
      } },
      Merger.new.merge_workitems(new_workitems.reverse, 'isolate'))
  end

  def test_stack

    assert_equal(
      { 'fields' => {
          'stack' => [ { 'a' => 0, 'b' => -1 }, { 'a' => 1 } ],
          'stack_attributes' => {}
      } },
      Merger.new.merge_workitems(new_workitems, 'stack'))
    assert_equal(
      { 'fields' => {
          'stack' => [ { 'a' => 1 }, { 'a' => 0, 'b' => -1 } ],
          'stack_attributes' => {}
      } },
      Merger.new.merge_workitems(new_workitems.reverse, 'stack'))
  end

  def test_unknown

    assert_equal(
      { 'fields' => { 'a' => 0, 'b' => -1 } },
      Merger.new.merge_workitems(new_workitems, '???'))
    assert_equal(
      { 'fields' => { 'a' => 1 } },
      Merger.new.merge_workitems(new_workitems.reverse, '???'))
  end

  def test_union

    workitems = [
      new_workitem('a' => 0, 'b' => [ 'x', 'y' ], 'c' => { 'aa' => 'bb' }),
      new_workitem('a' => 1, 'b' => [ 'y', 'z' ], 'c' => { 'cc' => 'dd' })
    ]

    assert_equal(
      { 'fields' => {
        'a' => 1,
        'b' => [ 'x', 'y', 'z' ],
        'c' => { 'aa' => 'bb', 'cc' => 'dd' }
      } },
      Merger.new.merge_workitems(workitems, 'union'))
  end

  def test_concat

    workitems = [
      new_workitem('a' => 0, 'b' => [ 'x', 'y' ], 'c' => { 'aa' => 'bb' }),
      new_workitem('a' => 1, 'b' => [ 'y', 'z' ], 'c' => { 'cc' => 'dd' })
    ]

    assert_equal(
      { 'fields' => {
        'a' => 1,
        'b' => [ 'x', 'y', 'y', 'z' ],
        'c' => { 'aa' => 'bb', 'cc' => 'dd' }
      } },
      Merger.new.merge_workitems(workitems, 'concat'))
  end
end

