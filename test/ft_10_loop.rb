
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'flowtestbase'


$s = (0..9).to_a.join("\n").strip


class FlowTest10 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  def test_loop_0

    #log_level_to_debug

    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <!--reval>$i = 0</reval-->
    <reval>sv("i", 0)</reval>
    <loop>
      <print>${i}</print>
      <reval>sv("i", lv("i") + 1)</reval>
      <if>
        <equals value="${i}" other-value="10" />
        <break/>
      </if>
    </loop>
  </sequence>
</process-definition>''',
    $s)
  end

  def test_loop_1
    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <!--reval>$i = 0</reval-->
    <set var="i"><a><number>0</number></a></set>
    <loop>
      <print>${i}</print>
      <reval>sv("i", lv("i") + 1)</reval>
      <if rtest="${i} == 10">
        <break/>
      </if>
    </loop>
  </sequence>
</process-definition>''',
    $s)
  end

  def test_loop_2
    #log_level_to_debug
    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <set var="i"><a><number>0</number></a></set>
    <loop>
      <print>${i}</print>
      <reval>sv("i", lv("i") + 1)</reval>
      <break if="${i} == 10" />
    </loop>
  </sequence>
</process-definition>''',
    $s)
  end

  def _test_loop_3
    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <set var="i"><a><number>0</number></a></set>
    <loop>
      <print>${i}</print>
      <reval>sv("i", lv("i") + 1)</reval>
      <break if="${r:lv(\'i\') == 10}" />
    </loop>
  </sequence>
</process-definition>''',
    $s)
  end

  def test_loop_4
    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <set var="i"><a><number>0</number></a></set>
    <loop>
      <print>${i}</print>
      <reval>sv("i", lv("i") + 1)</reval>
      <break rif="${i} == 10" />
    </loop>
  </sequence>
</process-definition>''',
    $s)
  end

  def test_loop_5

    #log_level_to_debug
      # causes test to fail (logging X vs $SAFE level 3)

    dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
  <sequence>
    <set var="i"><a><number>0</number></a></set>
    <loop>
      <set field="f">
        <reval>sv("i", lv("i") + 1)</reval>
      </set>
      <print>${i}</print>
      <break if="${f:f}" />
    </loop>
  </sequence>
</process-definition>''',
    '1')
  end

end

