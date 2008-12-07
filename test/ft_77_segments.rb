
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest77 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  TEST0 = '<print>nada</print>'

  def test_0
    dotest TEST0, 'nada'
  end


  TEST1 = '_print "nada"'

  def test_1
    dotest TEST1, 'nada'
  end

end

