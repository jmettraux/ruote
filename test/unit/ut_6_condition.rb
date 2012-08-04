
#
# testing ruote
#
# Sun Jun 14 17:30:43 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/svc/treechecker'
require 'ruote/svc/expression_map'


class ConditionTest < Test::Unit::TestCase

  class FakeExpression

    def initialize(h)
      @h = h
    end
    def attribute(k)
      @h[k]
    end
  end

  def assert_apply(h)

    e = FakeExpression.new(h)
    a = [ e.attribute(:if), e.attribute(:unless) ]

    assert(
      Ruote::Exp::Condition.apply?(*a),
      "exp #{h.inspect} was meant to be applied (#{a.inspect})")
  end

  def assert_skip(h)

    e = FakeExpression.new(h)
    a = [ e.attribute(:if), e.attribute(:unless) ]

    assert(
      ! Ruote::Exp::Condition.apply?(*a),
      "exp #{h.inspect} was meant to be skipped (#{a.inspect})")
  end

  def assert_b(b, conditional=nil)

    if conditional == nil
      conditional = b
      b = true
    end

    assert_equal(
      b,
      Ruote::Exp::Condition.true?(conditional),
      ">#{conditional}< was expected to be #{b}")
  end

  def test_blank

    assert_b(false, '')
    assert_b(false, ' ')
    assert_b(true, true)
    assert_b(false, false)
  end

  def test_if

    assert_skip :if => 'true == false'
    assert_skip :if => "'true' == 'false'"
    assert_skip :if => '"true" == "false"'

    assert_skip :if => ''
    assert_skip :if => ' '

    assert_apply :if => 'a == a'
    assert_apply :if => '"a" == "a"'

    assert_apply :if => 'blah blah blah'
  end

  def test_unless

    assert_apply :unless => 'true == false'
    assert_skip :unless => 'false == false'
  end

  def test_set

    assert_apply :if => 'true set'
    assert_apply :if => "'true' set"
    assert_apply :if => '"true" set'

    assert_apply :if => 'true is set'
    assert_apply :if => '"true" is set'
    assert_apply :if => "'true' is set"
    assert_skip :if => 'true is not set'
  end

  def test_illegal_code

    assert_apply :if => 'exit'
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

  def test_number_comparison

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

    assert_apply :if => 'a == a '
    assert_apply :if => ' a == a '
    assert_apply :if => ' a == a'
    assert_apply :if => 'a ==  a'
    assert_apply :if => 'a  == a'
    assert_apply :if => 'a==a'
  end

  def test_boolean_literals

    assert_b true, true
    assert_b false, false
  end

  def test_complex_strings

    assert_b true, "'some dude' == 'some dude'"
    assert_b true, "some dude == \"some dude\""
    assert_b true, "some dude == 'some dude'"

    assert_b false, "'some other dude' == 'some dude'"
    assert_b false, "some other dude == 'some dude'"
  end

  def test_numbers

    assert_b true, '2.310000 > 0'
    assert_b false, '2.310000 < 0'
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

  def assert_e(target, code)

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

    assert_e 'Loan', 'Loan'
    assert_e 'Loan/Grant', 'Loan/Grant'
    assert_e 'Loan/Grant', 'Loan / Grant'

    assert_e 'redo', '"redo"'
  end

  def test_something_or_not

    assert_b "something"
    assert_b false, ""
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

  def test_in

    assert_b "1 in [1, 2]"
    assert_b "1 in {1 => 2}"

    assert_b false, "3 in [1, 2]"
    assert_b false, "2 in {1 => 2}"

    assert_b "a in [a, b]"
    assert_b "'a' in [a, b]"
  end

  def test_not_in

    assert_b "7 not in [1, 2]"
    assert_b "2 not in {1 => 2}"

    assert_b false, "1 not in [1, 2]"
    assert_b false, "1 not in {1 => 2}"
  end

  def test_in_gone_bad

    assert_b false, "1 in [1 2]"
    assert_b false, "1 in {x}"
  end

  def test_matching

    assert_b "alpha =~ /^a/"
    assert_b "'alpha toto' =~ /^a/"
    assert_b false, "alpha =~ /^b/"
  end
end

