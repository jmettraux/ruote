
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest1b < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  def test_unset_6
    dotest(\
'''<process-definition name="unset_6" revision="0">
  <sequence>
    <set variable="/x" value="y" />
    <print>set ${x}</print>
    <sub0/>
    <print>unset ${x}</print>
  </sequence>
  <process-definition name="sub0">
    <unset variable="/x" />
  </process-definition>
</process-definition>''', 'set y
unset')
  end

end

