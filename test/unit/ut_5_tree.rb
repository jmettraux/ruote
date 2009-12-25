
#
# testing ruote
#
# Thu May 21 15:29:48 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/engine/process_status'


class TreeTest < Test::Unit::TestCase

  def test_decompose_tree

    assert_equal(
      {"0"=>["define", {"name"=>"nada"}],
       "0_0"=>["sequence", {}],
       "0_0_0"=>["alpha", {}],
       "0_0_1"=>["bravo", {}]},
      Ruote.decompose_tree(
        ["define", {"name"=>"nada"}, [
          ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
        ]]))
  end

  def test_decompose_sub_tree

    assert_equal(
      {"0_1"=>["define", {"name"=>"nada"}],
       "0_1_0"=>["sequence", {}],
       "0_1_0_0"=>["alpha", {}],
       "0_1_0_1"=>["bravo", {}]},
      Ruote.decompose_tree(
        ["define", {"name"=>"nada"}, [
          ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
        ]], '0_1'))
  end

  def test_recompose_tree

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
      ]],
      Ruote.recompose_tree(
        {"0"=>["define", {"name"=>"nada"}],
         "0_0"=>["sequence", {}],
         "0_0_0"=>["alpha", {}],
         "0_0_1"=>["bravo", {}]}))
  end
end

