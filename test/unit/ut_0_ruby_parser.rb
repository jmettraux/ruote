
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
end

