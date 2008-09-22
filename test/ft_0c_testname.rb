
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Dec 25 14:27:48 JST 2006
#

require 'flowtestbase'


class TestTestName < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  def test_name_of_test
    dotest(
      """
<process-definition name='#{name_of_test}' revision='0'>
  <print>#{name_of_test}</print>
</process-definition>
      """.strip,
      'name_of_test')
  end

end

