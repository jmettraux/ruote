
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/filterdef'


class FilterTest < Test::Unit::TestCase

  def test_0

    f0 = OpenWFE::FilterDefinition.new
    f0.closed = true
    f0.add_field('a', 'r')
    f0.add_field('b', 'rw')
    f0.add_field('c', '')

    m0 = {
      'a' => 'A',
      'b' => 'B',
      'c' => 'C',
      'd' => 'D',
    }

    m1 = f0.filter_in m0

    #require 'pp'; pp m0
    #require 'pp'; pp m1
    assert_equal m1, { 'a' => 'A', 'b' => 'B' }

    f0.closed = false

    m2 = f0.filter_in m0

    #require 'pp'; pp m0
    #require 'pp'; pp m2
    assert_equal m2, { 'a' => 'A', 'b' => 'B', 'd' => 'D' }
  end

  def test_1

    f0 = OpenWFE::FilterDefinition.new
    f0.closed = false
    f0.add_ok = true
    f0.remove_ok = true
    f0.add_field('a', 'r')
    f0.add_field('b', 'rw')
    f0.add_field('c', '')

    m0 = {
      'a' => 'A',
      'b' => 'B',
      'c' => 'C',
      'd' => 'D',
    }

    #
    # 0

    m1 = {
      'z' => 'Z'
    }

    m2 = f0.filter_out m0, m1

    #require 'pp'; pp m2
    assert_equal m2, {'z'=>'Z'}

    #
    # 1

    f0.remove_ok = false

    m2 = f0.filter_out m0, m1

    #require 'pp'; pp m2
    assert_equal m2, {'a'=>'A', 'b'=>'B', 'c'=>'C', 'z'=>'Z', 'd'=>'D'}

    #
    # 2

    f0.remove_allowed = true

    m1 = {
      'a' => 0,
      'b' => 1,
      'c' => 2,
      'd' => 3
    }

    m2 = f0.filter_out m0, m1

    #require 'pp'; pp m2
    assert_equal m2, {'a'=>'A', 'b'=>1, 'c'=>'C', 'd'=>3}
  end

  def test_2

    f0 = OpenWFE::FilterDefinition.new
    f0.closed = true
    f0.add_field('a', 'r')
    f0.add_field('b', 'rw')
    f0.add_field('c', '')

    h = f0.to_h

    assert_equal(
      {"class"=>"OpenWFE::FilterDefinition", "fields"=>[{"regex"=>"--- a\n", "class"=>"OpenWFE::FilterDefinition::Field", "permissions"=>"r"}, {"regex"=>"--- b\n", "class"=>"OpenWFE::FilterDefinition::Field", "permissions"=>"rw"}, {"regex"=>"--- c\n", "class"=>"OpenWFE::FilterDefinition::Field", "permissions"=>""}], "add_ok"=>true, "remove_ok"=>true, "closed"=>true},
      h)

    f1 = OpenWFE::FilterDefinition.from_h(h)

    assert_equal(h, f1.to_h)
  end

end

