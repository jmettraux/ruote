
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require 'flowtestbase'


class FlowTest2 < Test::Unit::TestCase
  include FlowTestBase

  # test_con_0 got moved to ft_2c_concurrence.rb

  def test_1

    #log_level_to_debug

    dotest(
'''<process-definition name="ft_2_concurrence" revision="1">
  <concurrence
    count="1"
  >
    <print>a</print>
    <sequence>
      <sleep for="10s" />
      <print>b</print>
    </sequence>
  </concurrence>
</process-definition>''',
      "a",
      true)
  end

  def test_2

    #log_level_to_debug

    dotest(
'''<process-definition name="ft_2_concurrence" revision="2">
  <concurrence over-if="true">
    <sequence>
      <sleep for="1s"/>
      <print>a</print>
    </sequence>
    <print>b</print>
  </concurrence>
</process-definition>''',
      "b",
      true)
  end

  def test_3

    log_level_to_debug

    dotest(
'''<process-definition name="ft_2_concurrence" revision="3">
  <concurrence over-if="${over}">
    <print>a</print>
    <set variable="over" value="true" />
  </concurrence>
</process-definition>''',
      'a',
      true)
  end

  def test_4

    #log_level_to_debug

    dotest(
'''<process-definition name="ft_2_concurrence" revision="4">
  <concurrence over-if="${nada}">
    <sequence>
      <sleep for="1s"/>
      <print>a</print>
    </sequence>
    <print>b</print>
  </concurrence>
</process-definition>''',
      "b\na",
      true)
  end

  def test_5

    #log_level_to_debug

    dotest(
'''<process-definition name="ft_2_concurrence" revision="5">
  <concurrence over-if="false">
    <sequence>
      <sleep for="1s"/>
      <print>a</print>
    </sequence>
    <print>b</print>
  </concurrence>
</process-definition>''',
      "b\na",
      true)
  end

  class TestDefinition6 < OpenWFE::ProcessDefinition
    sequence do
      concurrence :over_if => "1 == 1" do
        sequence do
          _sleep :for => "350"
          _print "a"
        end
        _print "b"
      end
      _print "c"
    end
  end

  def test_6

    #log_level_to_debug

    dotest TestDefinition6, "b\nc"
  end

end

