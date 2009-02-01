
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require 'rubygems'

require 'test/unit'

require 'rufus/dollar'
require 'openwfe/utils'
require 'openwfe/expressions/raw'
#require 'openwfe/def'
require 'openwfe/expressions/fe_define'
require 'openwfe/expressions/expressionmap'

#
# testing misc things
#

class MiscTest < Test::Unit::TestCase

  #def test_starts_with
  #  assert OpenWFE::starts_with("//a", "//")
  #  assert (not OpenWFE::starts_with("/a", "//"))
  #end

  def test_ends_with

    assert OpenWFE::ends_with("c'est la fin", "fin")
  end

  def test_ensure_for_filename

    assert_equal OpenWFE::ensure_for_filename("abc"), "abc"
    assert_equal OpenWFE::ensure_for_filename("a/c"), "a_c"
    assert_equal OpenWFE::ensure_for_filename("a\\c"), "a_c"
    assert_equal OpenWFE::ensure_for_filename("a*c"), "a_c"
    assert_equal OpenWFE::ensure_for_filename("a+?"), "a__"
    assert_equal OpenWFE::ensure_for_filename("a b"), "a_b"
  end

  def test_clean_path

    assert_equal OpenWFE::clean_path("my//file/path"), "my/file/path"
    assert_equal OpenWFE::clean_path("my//file//path"), "my/file/path"
  end

  def test_stu

    assert_equal "a_b_c", OpenWFE::stu("a b c")
  end

  def test_grep_0

    assert OpenWFE::grep("sputnik", "Rakefile").empty?
    assert_equal 1, OpenWFE::grep("Mettraux", "Rakefile").size

    OpenWFE::grep "Mettraux", "Rakefile" do |line|
      assert_match "Mettraux", line
    end
  end

  def test_expmap_get_classes

    em = OpenWFE::ExpressionMap.new

    assert_equal(
      [
        OpenWFE::ParticipantExpression,
        OpenWFE::SleepExpression,
        OpenWFE::CronExpression,
        OpenWFE::WhenExpression,
        OpenWFE::WaitExpression,
        #OpenWFE::ReserveExpression,
        OpenWFE::ListenExpression,
        OpenWFE::TimeoutExpression,
        OpenWFE::HpollExpression,
        OpenWFE::Environment
      ],
      em.get_expression_classes(Rufus::Schedulable))
  end
end
