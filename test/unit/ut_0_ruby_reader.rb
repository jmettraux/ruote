
#
# testing ruote
#
# Tue May 12 15:31:26 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/reader'


class UtRubyReaderTest < Test::Unit::TestCase

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

  def test_treechecker

    #assert_raise Nada do
      Ruote::Reader.read %{ Ruote.define { alpha } }
    #end

    assert_raise Ruote::Reader::Error do
      Ruote::Reader.read %{ Ruote.define { abort } }
    end
    assert_raise Ruote::Reader::Error do
      Ruote::Reader.read %{ Ruote.define { exit } }
    end
    assert_raise Ruote::Reader::Error do
      Ruote::Reader.read %{ Ruote.define { exit! } }
    end

    assert_raise Ruote::Reader::Error do
      Ruote::Reader.read %{ Ruote.define { x = Kernel } }
    end

    assert_raise Ruote::Reader::Error do
      Ruote::Reader.read %{ Ruote.define { module Nada; end } }
    end

    assert_raise Ruote::Reader::Error do
      Ruote::Reader.read %{ Ruote.define { File.read('stuff') } }
    end

    assert_raise Ruote::Reader::Error do
      Ruote::Reader.read %{ Ruote.define { at_exit { } } }
    end

    assert_raise Ruote::Reader::Error do
      Ruote::Reader.read %{ Ruote.define { def nada; end } }
    end
  end

  def test_attribute_text_regexp

    tree = Ruote.define do
      given "${target}" do
        of "/^employee-/" do
        end
        of /^customer-/ do
        end
      end
    end

    assert_equal(
      ["define", {}, [
        ["given", {"${target}"=>nil}, [
          ["of", {"/^employee-/"=>nil}, []],
          ["of", {"/^customer-/"=>nil}, []]]]]],
      tree)
  end

  def test_attribute_value_regexp

    tree = Ruote.define do
      subprocess 'alpha', :match => /^nada$/
    end

    assert_equal(
      ["define", {}, [["subprocess", {"alpha"=>nil, "match"=>"/^nada$/"}, []]]],
      tree)
  end

  def test_attribute_value_regexp_deep

    tree = Ruote.define do
      alpha :filter => { :in => [ { :field => /^private_/ } ] }
    end

    assert_equal(
      [ "define", {}, [
        [ "alpha", { "filter" => { "in" => [ { "field" => '/^private_/' } ] } }, [] ]
      ] ],
      tree)
  end

  def test_proc

    tree = Ruote.define do
      set 'v:v' => "lambda { |wi| p wi }\n"
      set 'v:v' => lambda { |wi| p wi }
      set 'v:v' => { 'on_workitem' => lambda { |wi| p wi } }
    end

    assert_equal(
      [ 'define', {}, [
        [ 'set', { 'v:v' => "lambda { |wi| p wi }\n" }, [] ],
        [ 'set', { 'v:v' => "proc { |wi| p wi }\n" }, [] ],
        [ 'set', { 'v:v' => { 'on_workitem' => "proc { |wi| p wi }\n" } }, [] ] ] ],
      tree)
  end
end

