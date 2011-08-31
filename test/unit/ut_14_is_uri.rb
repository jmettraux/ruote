
#
# testing ruote
#
# Tue Sep  1 13:39:43 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/util/misc'


class UtIsUriTest < Test::Unit::TestCase

  def test_is

    assert Ruote.is_uri?('definition.rb')
    assert Ruote.is_uri?('/definition.xml')
    assert Ruote.is_uri?('http://nada.example.com/')
  end

  def test_is_not

    assert ! Ruote.is_uri?('toto')
    assert ! Ruote.is_uri?('definition. nada')
  end
end

