
#
# Testing Ruote
#
# Wed Aug 26 16:25:42 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/util/jash'


class Car
  attr_accessor :brand, :doors
  def initialize
    @brand = 'citroen'
    @doors = [ 'left', 'right' ]
  end
end

class Bike
  attr_accessor :brand, :doors
  def initialize
    @brand = 'piaggio'
    @doors = [ 'left', 'right' ]
  end
  def to_yaml_properties
    ps = instance_variables.sort
    ps.delete('@doors')
    ps.delete(:@doors)
    ps
  end
end

class JashTest < Test::Unit::TestCase

  #def setup
  #end
  #def teardown
  #end

  def test_encode

    assert_raise ArgumentError do
      Ruote::Jash.encode(:wrong)
    end

    assert_equal(nil, Ruote::Jash.encode(nil))
    assert_equal(1, Ruote::Jash.encode(1))
    assert_equal(1.0, Ruote::Jash.encode(1.0))
    assert_equal(true, Ruote::Jash.encode(true))
    assert_equal(false, Ruote::Jash.encode(false))

    assert_equal({}, Ruote::Jash.encode({}))
    assert_equal([], Ruote::Jash.encode([]))

    assert_equal(
      {"_ruote_jash_class_"=>"Car", "@brand"=>"citroen", "@doors"=>["left", "right"]},
      Ruote::Jash.encode(Car.new))

    assert_equal(
      {"_ruote_jash_class_"=>"Bike", "@brand"=>"piaggio"},
      Ruote::Jash.encode(Bike.new))

    assert_raise ArgumentError do
      Ruote::Jash.encode({ :a => 'A' })
    end
  end

  def test_decode

    assert_raise ArgumentError do
      Ruote::Jash.decode(:wrong)
    end

    assert_equal(nil, Ruote::Jash.decode(nil))
    assert_equal(1, Ruote::Jash.decode(1))
    assert_equal(1.0, Ruote::Jash.decode(1.0))
    assert_equal(true, Ruote::Jash.decode(true))
    assert_equal(false, Ruote::Jash.decode(false))

    assert_equal({}, Ruote::Jash.decode({}))
    assert_equal([], Ruote::Jash.decode([]))

    c = Ruote::Jash.decode({
      "_ruote_jash_class_" => "Car",
      "@brand" => "citroen",
      "@doors" => [ "left", "right" ]})

    assert_equal Car, c.class
    assert_equal 2, c.doors.size
  end

  def test_constantize

    assert_equal(
      Test::Unit::TestCase,
      Ruote::Jash.constantize('Test::Unit::TestCase'))
  end
end

