
#
# Testing Ruote
#
# Tue May 12 15:31:26 JST 2009
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'ruote/parser/ruby_dsl'


class RubyParserTest < Test::Unit::TestCase

  def test_sequence

    tree = Ruote.define :name => 'nada' do
      sequence do
        alpha
        bravo
      end
    end

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
      ]],
      tree)
  end

  def test_echo

    tree = Ruote.define :name => 'nada' do
      echo 'a'
    end

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["echo", {}, ["a"]]
      ]],
      tree)
  end

  def test_echo_with_escape

    tree = Ruote.define :name => 'nada' do
      echo 'a', :escape => true
    end

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["echo", {"escape"=>true}, ["a"]]
      ]],
      tree)
  end
end

