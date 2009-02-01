
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Dec 10 18:02:59 JST 2007
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/expool/expstorage'


class Vehicle
end
class Car < Vehicle
end
class Animal
end

class ExpstorageTest < Test::Unit::TestCase

  def test_class_accepted

    esb = Object.new
    class << esb
      include OpenWFE::ExpressionStorageBase
    end

    assert (esb.class_accepted?(Vehicle.new, nil, nil))
    assert (esb.class_accepted?(Vehicle.new, [ Vehicle ], nil))
    assert (not esb.class_accepted?(Vehicle.new, nil, [ Vehicle ]))

    assert (esb.class_accepted?(Car.new, [ Vehicle ], nil))
    assert (not esb.class_accepted?(Car.new, nil, [ Vehicle ]))
  end
end
