
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'flowtestbase'


class FlowTest0b < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  def test_sequence
    dotest(
      '''
<process-definition name="n" revision="0">
  <sequence>
    <print>a</print>
    <print>b</print>
  </sequence>
</process-definition>
      '''.strip,
      "a\nb")
  end

end

