
#
# Testing Ruote
#
# Fri Jul 31 13:05:37 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/util/json'


class JsonTest < Test::Unit::TestCase

  def setup
    Ruote::Json.backend = Ruote::Json::NONE
  end
  #def teardown
  #end

  def test_none

    assert_raise RuntimeError do
      Ruote::Json.decode('nada')
    end
  end

  def test_decode

    require 'json'

    assert_raise RuntimeError do
      Ruote::Json.decode('nada')
    end

    Ruote::Json.backend = Ruote::Json::JSON
    assert_equal [ 1, 2, 3 ], Ruote::Json.decode("[ 1, 2, 3 ]")
  end

  def test_encode

    require 'json'

    assert_raise RuntimeError do
      Ruote::Json.encode('nada')
    end

    Ruote::Json.backend = Ruote::Json::JSON
    assert_equal "[1,2,3]", Ruote::Json.encode([ 1, 2, 3 ])
  end
end

