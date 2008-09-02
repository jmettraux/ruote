
#
# Testing OpenWFEru (Ruote)
#
# John Mettraux at openwfe.org
#
# Mon Dec 25 14:27:48 JST 2006
#

require 'flowtestbase'


class FlowTest8 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  def test_forget_0
    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <concurrence
      count="1"
    >
      <forget>
        <print>a</print>
      </forget>
      <sequence>
        <sleep for="500" />
        <print>b</print>
      </sequence>
    </concurrence>
    <print>c</print>
  </sequence>
</process-definition>''',
      "a\nc")
  end

end

