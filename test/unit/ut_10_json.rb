
#
# Testing Ruote
#
# Fri Jul 31 13:05:37 JST 2009
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'ruote/util/json'


class JsonTest < Test::Unit::TestCase

  def test_none

    assert_raise RuntimeError do
      Ruote::Json.decode('nada')
    end
  end

  def test_json

    require 'json'

    assert_raise RuntimeError do
      Ruote::Json.decode('nada')
    end

    Ruote::Json.decoder = Ruote::Json::JSON
    assert_equal [ 1, 2, 3 ], Ruote::Json.decode("[ 1, 2, 3 ]")

    Ruote::Json.decoder = Ruote::Json::NONE
  end
end

