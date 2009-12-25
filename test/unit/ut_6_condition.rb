
#
# testing ruote
#
# Sun Jun 14 17:30:43 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/exp/expression_map'
require 'ruote/util/treechecker'


class ConditionTest < Test::Unit::TestCase

  class Conditional

    def treechecker
      return @tc if @tc
      @tc = Ruote::TreeChecker.new
      @tc.context = {}
      @tc
    end
  end

  class FakeExpression < Conditional

    def initialize (h)
      @h = h
    end
    def attribute (k)
      @h[k]
    end
  end

  def assert_not_skip (result, h)

    fe = FakeExpression.new(h)

    sif = fe.attribute(:if)
    sunless = fe.attribute(:unless)

    assert_equal result, Ruote::Exp::Condition.apply?(sif, sunless)
  end

  def assert_b (b, conditional)

    assert_equal(
      b,
      Ruote::Exp::Condition.true?(conditional),
      ">#{conditional}< was expected to be #{b}")
  end

  def test_if

    assert_not_skip false, :if => 'true == false'
    assert_not_skip false, :if => "'true' == 'false'"
    assert_not_skip false, :if => '"true" == "false"'

    assert_not_skip true, :if => 'a == a'
    assert_not_skip true, :if => '"a" == "a"'
  end

  def test_unless

    assert_not_skip true, :unless => 'true == false'
    assert_not_skip false, :unless => 'false == false'
  end

  def test_set

    assert_not_skip true, :if => 'true set'
    assert_not_skip true, :if => "'true' set"
    assert_not_skip true, :if => '"true" set'

    assert_not_skip true, :if => 'true is set'
    assert_not_skip true, :if => '"true" is set'
    assert_not_skip true, :if => "'true' is set"
    assert_not_skip false, :if => 'true is not set'
  end

  def test_illegal_code

    assert_not_skip true, :if => 'exit'
  end

  def test_true

    assert_b true, 'true == true'
    assert_b true, 'alpha == alpha'

    assert_b true, 'true is set'
    assert_b true, 'false is set'

    assert_b false, 'true is not set'
    assert_b false, 'is set'
    assert_b false, ' is set'
  end

  def test_bang_equal

    assert_b false, 'true != true'
    assert_b true, 'true != false'
  end

  def test_match

    assert_b false, 'alpha =~ bravo'
    assert_b true, 'alpha =~ al'
  end

  def test_number_comparision

    assert_b true, 'b > a'
    assert_b false, 'a > b'
    assert_b true, '100 > 10'
    assert_b true, '100 > 90'
    assert_b true, '100.0 > 90'
  end

  def test_emptiness

    assert_b true, ' == '
    assert_b false, " == ''"
    assert_b false, ' == ""'
  end

  def test_strip

    assert_not_skip true, :if => 'a == a '
    assert_not_skip true, :if => ' a == a '
    assert_not_skip true, :if => ' a == a'
    assert_not_skip true, :if => 'a ==  a'
    assert_not_skip true, :if => 'a  == a'
    assert_not_skip true, :if => 'a==a'
  end
end

