
#
# testing ruote
#
# Wed Jul 15 09:27:20 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/reader/ruby_dsl'
require 'ruote/tree_dot'


class TreeDotTest < Test::Unit::TestCase

  def test_sequence

    tree = Ruote.define :name => 'test' do
      sequence do
        alpha
        bravo
      end
    end

    #puts Ruote.tree_to_dot(tree)

    assert_equal(
      %{
digraph "ruote process definition" {
  "0" [ label = "define {'name'=>'test'}" ];
  "0_0" [ label = "sequence {}" ];
  "0_0_0" [ label = "alpha {}" ];
  "0_0_1" [ label = "bravo {}" ];
  "0_0" -> "0_0_0";
  "0_0_1" -> "0_0";
  "0_0_0" -> "0_0_1";
  "0" -> "0_0";
  "0_0" -> "0";
}
      }.strip,
      Ruote.tree_to_dot(tree).strip)
  end

  def test_concurrence

    tree = Ruote.define :name => 'test' do
      concurrence do
        alpha
        bravo
      end
    end

    #puts Ruote.tree_to_dot(tree)

    assert_equal(
      %{
digraph "ruote process definition" {
  "0" [ label = "define {'name'=>'test'}" ];
  "0_0" [ label = "concurrence {}" ];
  "0_0_0" [ label = "alpha {}" ];
  "0_0_1" [ label = "bravo {}" ];
  "0_0" -> "0_0_0";
  "0_0_0" -> "0_0";
  "0_0" -> "0_0_1";
  "0_0_1" -> "0_0";
  "0" -> "0_0";
  "0_0" -> "0";
}
      }.strip,
      Ruote.tree_to_dot(tree).strip)
  end
end
