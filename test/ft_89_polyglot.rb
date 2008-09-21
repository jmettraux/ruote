
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Sep 20 23:40:10 JST 2008
#

require 'flowtestbase'


class FlowTest89 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  def test_0

    dotest(
      [ 'print', {}, [ 'alpha' ] ],
      'alpha')
  end

  def test_1

    dotest(
      '["print",{},["alpha"]]',
      'alpha')
  end

  def test_2

    dotest(
      "[ 'print', {}, [ 'alpha' ] ]",
      'alpha')
  end

  def test_3

    dotest(
      "--- \n- print\n- {}\n\n- - alpha\n",
      'alpha')
  end

end

