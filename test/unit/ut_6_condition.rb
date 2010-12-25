
#
# testing ruote
#
# Sun Jun 14 17:30:43 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/svc/treechecker'
require 'ruote/svc/expression_map'


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

  def assert_b (b, conditional=nil)

    if conditional == nil
      conditional = b
      b = true
    end

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

    assert_b false, ' == '
    assert_b false, " == ''"
    assert_b false, ' == ""'
    assert_b false, ' == a'
    assert_b false, 'a == '
  end

  def test_strip

    assert_not_skip true, :if => 'a == a '
    assert_not_skip true, :if => ' a == a '
    assert_not_skip true, :if => ' a == a'
    assert_not_skip true, :if => 'a ==  a'
    assert_not_skip true, :if => 'a  == a'
    assert_not_skip true, :if => 'a==a'
  end

  def test_boolean_literals

    assert_b true, true
    assert_b false, false
  end

  def test_complex_strings

    assert_b true, "'some dude' == 'some dude'"
    assert_b true, "some dude == \"some dude\""
  end

  def test_and_or

    assert_b "1 and 2 and 3"
    assert_b "1 && 2 && 3"

    assert_b "1 or 2 or 3"
    assert_b "1 || 2 || 3"

    assert_b true, "true or false"

    assert_b true, "true and (true or false)"
    assert_b false, "true and (true and false)"

    assert_b true, "'a' and ('b' and 'c')"
  end

  def test_not

    assert_b true, "not false"
    assert_b false, "not true"
    assert_b true, "! false"
    assert_b false, " ! true"
  end

  def assert_e (target, code)

    assert_equal(
      target,
      Ruote::Exp::Condition.eval(code),
      ">#{code}< was expected to eval to #{target.inspect}")
  end

  def test_eval

    assert_e nil, "nil"

    assert_e true, "true"
    assert_e false, "false"
    assert_e 'alice', '"alice"'
    assert_e 1, '1'

    assert_e([ 1, 2, 3 ], "[ 1, 2, 3 ]")
    assert_e({ 'a' => 2, 'b' => 2.0 }, "{ 'a' => 2, 'b' => 2.0 }")

    assert_e /^a/, "/^a/"
  end

  def test_is_empty

    assert_b "'' empty"
    assert_b "'' is empty"
    assert_b '"" empty'
    assert_b '"" is empty'

    assert_b "[] empty"
    assert_b "[] is empty"

    assert_b "{} empty"
    assert_b "{} is empty"

    assert_b false, "[1] is empty"
    assert_b false, "{1=>2} is empty"
  end

  def test_is_not_empty

    assert_b false, "'' not empty"
    assert_b false, "'' is not empty"
    assert_b false, '"" not empty'
    assert_b false, '"" is not empty'

    assert_b false, "[] not empty"
    assert_b false, "[] is not empty"

    assert_b false, "{} not empty"
    assert_b false, "{} is not empty"

    assert_b true, "[1] is not empty"
    assert_b true, "{1=>2} is not empty"
  end

  def test_null

    assert_b "nil == nil"
    assert_b "1 != nil"
    assert_b false, "1 == nil"
    assert_b false, "nil != nil"

    assert_b "nil null"
    assert_b "nil is null"

    assert_b false, "nil not null"
    assert_b false, "nil is not null"

    assert_b false, "1 null"
    assert_b false, "1 is null"

    assert_b true, "1 not null"
    assert_b true, "1 is not null"
  end

  def test_comparators

    assert_b "alpha =~ /^a/"
    assert_b false, "alpha =~ /^b/"
  end
end

