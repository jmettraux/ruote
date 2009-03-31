
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/utils'


class UtilsTest < Test::Unit::TestCase

  def test_ends_with

    assert OpenWFE::ends_with('c\'est la fin', 'fin')
  end

  def test_ensure_for_filename

    assert_equal OpenWFE::ensure_for_filename('abc'), 'abc'
    assert_equal OpenWFE::ensure_for_filename('a/c'), 'a_c'
    assert_equal OpenWFE::ensure_for_filename('a\\c'), 'a_c'
    assert_equal OpenWFE::ensure_for_filename('a*c'), 'a_c'
    assert_equal OpenWFE::ensure_for_filename('a+?'), 'a__'
    assert_equal OpenWFE::ensure_for_filename('a b'), 'a_b'
  end

  def test_clean_path

    assert_equal OpenWFE::clean_path('my//file/path'), 'my/file/path'
    assert_equal OpenWFE::clean_path('my//file//path'), 'my/file/path'
  end

  def test_stu

    assert_equal 'a_b_c', OpenWFE::stu('a b c')
  end

  def test_grep_0

    assert OpenWFE::grep('sputnik', 'Rakefile').empty?
    assert_equal 1, OpenWFE::grep('Mettraux', 'ruote.gemspec').size

    OpenWFE::grep 'Mettraux', 'Rakefile' do |line|
      assert_match 'Mettraux', line
    end
  end
end

