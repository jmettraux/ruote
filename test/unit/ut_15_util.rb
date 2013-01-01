
#
# testing ruote
#
# Sat Sep 19 13:27:18 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

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

  def test_regex_or_s

    assert_equal /bravo/, Ruote.regex_or_s('/bravo/')
    assert_equal 'nada', Ruote.regex_or_s('nada')
    assert_equal nil, Ruote.regex_or_s(nil)
  end

  class Klass
    def initialize(s)
      @s = s
    end
  end

  def test_fulldup

    a = Klass.new('hello')
    b = Ruote.fulldup(a)

    assert_equal Klass, b.class
    assert_not_equal a.object_id, b.object_id
    assert_equal 'hello', b.instance_variable_get(:@s)
  end

  def test_camelize

    assert_equal(
      'alphaBravoCharly', Ruote.camelize('alpha_bravo_charly'))
    assert_equal(
      'AlphaBravoCharly', Ruote.camelize('alpha_bravo_charly', true))
  end

  def test_decamelize

    assert_equal(
      'alpha_bravo_charly', Ruote.decamelize('alphaBravoCharly'))
    assert_equal(
      'alpha_bravo_charly', Ruote.decamelize('AlphaBravoCharly'))
  end

  def test_insp

    assert_equal(
      '{a: [a, b], c: 3, d: true}',
      Ruote.insp({ 'a' => %w[ a b ], 'c' => 3, 'd' => true }))
  end

  def test_pps

    assert_equal(
      "{\"a\"=>[\"a\", \"b\"], \"c\"=>3, \"d\"=>true}\n",
      Ruote.pps({ 'a' => %w[ a b ], 'c' => 3, 'd' => true }))
  end
end

