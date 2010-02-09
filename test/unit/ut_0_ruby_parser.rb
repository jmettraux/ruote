
#
# testing ruote
#
# Tue May 12 15:31:26 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/parser/ruby_dsl'


class UtRubyParserTest < Test::Unit::TestCase

  #def test_whatever
  #  tree = Ruote.define do
  #    set "f:x" => 12
  #  end
  #  p tree
  #end

  def test_sequence

    tree = Ruote.define :name => 'nada' do
      sequence do
        participant :ref => :alpha
        bravo
      end
    end

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [
          ["participant", {"ref"=>"alpha"}, []], ["bravo", {}, []]]]]],
      tree)
  end

  def test_empty_sub

    tree = Ruote.define :name => 'nada' do
      sequence do
        alpha
        bravo
      end
      define 'toto' do
      end
    end

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]],
        ["define", {"toto"=>nil}, []]
      ]],
      tree)
  end

  def test_echo

    tree = Ruote.define :name => 'nada' do
      echo 'a'
    end

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["echo", {"a"=>nil}, []]
      ]],
      tree)
  end

  def test_echo_with_escape

    tree = Ruote.define :name => 'nada' do
      echo 'a', :escape => true
    end

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["echo", {"a"=>nil, "escape"=>true}, []]
      ]],
      tree)
  end

  def test_set

    tree = Ruote.define :name => 'nada' do
      set :var => 'v', :val => %w[ 1 2 3 4 ]
    end

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["set", {"val"=>["1", "2", "3", "4"], "var"=>"v"}, []]
      ]],
      tree)
  end

  #def test_set_nested
  #  tree = Ruote.define :name => 'nada' do
  #    set do
  #      %w[ 1 2 3 4 ]
  #    end
  #  end
  #  assert_equal(
  #    ["define", {"name"=>"nada"}, [
  #      ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
  #    ]],
  #    tree)
  #end

  def test_escaping_ruby_keywords

    tree = Ruote.define do
      _redo 'nada'
    end

    assert_equal(
      ["define", {}, [["redo", {"nada"=>nil}, []]]],
      tree)
  end

  def test_to_tree

    assert_equal(
      [ 'sequence', {}, [ [ 'alpha', {}, [] ], [ 'bravo', {}, [] ] ] ],
      Ruote.to_tree { sequence { alpha; bravo } })
  end
end

