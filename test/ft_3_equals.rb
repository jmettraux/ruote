
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'flowtestbase'


class FlowTest3 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  def test_0
    dotest(
'''<process-definition name="equals_0" revision="0">
  <sequence>
    <equals value="a" other-value="a" />
    <print>${field:__result__}</print>
  </sequence>
</process-definition>''',
      'true')
  end

  def test_1
    dotest(
'''<process-definition name="equals_1" revision="0">
  <sequence>
    <equals value="a" other-value="b" />
    <print>${field:__result__}</print>
  </sequence>
</process-definition>''',
      "false")
  end

  def test_2
    log_level_to_debug
    dotest(
'''<process-definition name="if_0" revision="0">
  <if>
    <equals value="a" other-value="a" />
    <print>ok</print>
  </if>
</process-definition>''',
      'ok')
  end

  def test_3
    dotest(
'''<process-definition name="if_1" revision="0">
  <if>
    <equals value="a" other-value="a" />
    <print>ok</print>
    <print>nok</print>
  </if>
</process-definition>''',
      "ok")
  end

  def test_4
    dotest(
'''<process-definition name="if_2" revision="0">
  <if>
    <equals value="a" other-value="b" />
    <print>nok</print>
  </if>
</process-definition>''',
      "")
  end

  def test_5
    dotest(
'''<process-definition name="if_3" revision="0">
  <if>
    <equals value="a" other-value="b" />
    <print>nok</print>
    <print>ok</print>
  </if>
</process-definition>''', "ok")
  end

  def test_6
    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <set field="a" value="true" />
    <print>${f:a}</print>
    <if>
      <equals field-value="a" other-value="true" />
      <print>true</print>
      <print>bad test_equals_0</print>
    </if>
  </sequence>
</process-definition>''',
      "true\ntrue")
  end

  def test_7
    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <set variable="a" value="true" />
    <print>${a}</print>
    <if>
      <equals variable-value="a" other-value="true" />
      <print>true</print>
      <print>bad test_equals_1</print>
    </if>
  </sequence>
</process-definition>''',
      "true\ntrue")
  end

  def test_8
    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <set variable="a" value="true" />

    <equals variable="a" other-value="true" />
    <print>${f:__result__}</print>

    <equals variable="a" value="true" />
    <print>${f:__result__}</print>
  </sequence>
</process-definition>''',
      "true\ntrue")
  end

  def test_9

    #log_level_to_debug

    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <if test="3 > 2">
      <print>ok0</print>
    </if>
    <if test="3 > a">
      <print>bad</print>
      <print>ok1</print>
    </if>
    <if test="3>a">
      <print>bad</print>
      <print>ok2</print>
    </if>
    <if test="3 &gt; 2">
      <print>ok3</print>
      <print>bad</print>
    </if>
    <if test="1 &lt; 2.0">
      <print>ok4</print>
      <print>bad</print>
    </if>
  </sequence>
</process-definition>''',
      (0..4).collect { |i| "ok#{i}" }.join("\n"))
  end

end

