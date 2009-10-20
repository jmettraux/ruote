
#
# Testing Ruote
#
# Tue Oct 20 10:48:11 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/parser'


class PdefParserTest < Test::Unit::TestCase

  DEF0 = %{
    Ruote.define :name => 'nada' do
      sequence do
        alpha
        bravo
      end
    end
  }

  def test_from_string

    tree = Ruote::Parser.parse(DEF0)

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
      ]],
      tree)
  end

  def test_from_file

    fn = File.join(File.dirname(__FILE__), '_ut_16_def.rb')

    File.open(fn, 'w') { |f| f.write(DEF0) }

    tree = Ruote::Parser.parse(fn)

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
      ]],
      tree)

    File.delete(fn) # sooner or later, it will get erased
  end
end

