
#
# testing ruote
#
# Thu Aug 27 10:44:44 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/util/serializer'


class UtSerializerTest < Test::Unit::TestCase

  class Vehicle
    attr_accessor :type
    def initialize (t)
      @type = t
    end
  end

  #def setup
  #end
  #def teardown
  #end

  def test_yaml

    s = Ruote::Serializer.new(:yaml)

    data = s.encode(Vehicle.new('bike'))

    assert_match /^---/, data

    v = s.decode(data)

    assert_equal Vehicle, v.class
    assert_equal 'bike', v.type
  end

  def test_marshal

    s = Ruote::Serializer.new(:marshal)

    data = s.encode(Vehicle.new('bike'))

    v = s.decode(data)

    assert_equal Vehicle, v.class
    assert_equal 'bike', v.type
  end

  def test_marshal64

    s = Ruote::Serializer.new(:marshal64)

    data = s.encode(Vehicle.new('bike'))

    v = s.decode(data)

    assert_equal Vehicle, v.class
    assert_equal 'bike', v.type
  end
end

