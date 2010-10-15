
#
# testing ruote
#
# Sat Sep 19 13:27:18 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/util/misc'


class UtMiscTest < Test::Unit::TestCase

  def test_narrow_to_number

    assert_equal nil, Ruote.narrow_to_number(nil)
    assert_equal nil, Ruote.narrow_to_number('a')
    assert_equal nil, Ruote.narrow_to_number(Object.new)

    assert_equal 0, Ruote.narrow_to_number(0)
    assert_equal 1, Ruote.narrow_to_number(1)

    assert_equal 0.0, Ruote.narrow_to_number(0.0)
    assert_equal 1.0, Ruote.narrow_to_number(1.0)

    assert_equal 0, Ruote.narrow_to_number('0')
    assert_equal 1, Ruote.narrow_to_number('1')

    assert_equal 0.0, Ruote.narrow_to_number('0.0')
    assert_equal 1.0, Ruote.narrow_to_number('1.0')
  end

  def test_regex_from_s

    assert_equal /bravo/, Ruote.regex_from_s('(?-mix:bravo)')
    assert_equal nil, Ruote.regex_from_s('nada')
    assert_equal nil, Ruote.regex_from_s(nil)
  end

  def test_regex_or_s

    assert_equal /bravo/, Ruote.regex_or_s('(?-mix:bravo)')
    assert_equal 'nada', Ruote.regex_or_s('nada')
    assert_equal nil, Ruote.regex_or_s(nil)
  end
end

