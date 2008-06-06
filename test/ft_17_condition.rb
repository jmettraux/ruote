
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'flowtestbase'


class FlowTest17 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  def test_condition_0
    dotest(
'''<process-definition name="con" revision="0">
  <if test="a == a">
    <print>ok</print>
  </if>
</process-definition>''', "ok")
  end

  def test_condition_1
    dotest(
'''<process-definition name="con" revision="0">
  <if test="a == b">
    <print>ok</print>
  </if>
</process-definition>''', "")
  end

  def test_condition_2
    dotest(
'''<process-definition name="con" revision="0">
  <sequence>
    <set field="toto" value="nada" />
    <if test="${f:toto} == nada">
      <print>ok</print>
    </if>
  </sequence>
</process-definition>''', "ok")
  end

  def test_condition_3
    dotest(
'''<process-definition name="con" revision="0">
  <sequence>
    <set field="toto" value="true" />
    <if test="${f:toto}">
      <print>ok</print>
    </if>
  </sequence>
</process-definition>''', "ok")
  end

  def test_condition_4
    dotest(
'''<process-definition name="con" revision="0">
  <if rtest="1+2 == 3">
    <print>ok</print>
  </if>
</process-definition>''', "ok")
  end

  def test_condition_5
    dotest(
'''<process-definition name="con" revision="0">
  <if test="1+2 == 3">
    <print>ok</print>
    <print>nok</print>
  </if>
</process-definition>''', "ok")
  end

end

