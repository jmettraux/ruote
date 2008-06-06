
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'flowtestbase'


class FlowTest0d < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  def test_participant
    dotest(\
'''<process-definition name="n" revision="0">
  <participant ref="test-alpha" />
</process-definition>''', "test-alpha")
  end

end

