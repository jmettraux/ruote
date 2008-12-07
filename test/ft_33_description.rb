
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest33 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class TestDefinition0 < OpenWFE::ProcessDefinition
    description "nada"
    _print "${description}"
  end

  def test_0

    dotest TestDefinition0, "nada"
  end

  #
  # TEST 1

  def test_1
    dotest("""<process-definition name='test_1' revision='x'>
  <description>nada</description>
  <print>${description}</print>
</process-definition>
""", "nada")
  end

  #
  # TEST 2

  class TestDefinition2 < OpenWFE::ProcessDefinition
    description :lang => "fr" do "nada" end
    sequence do
      _print "${description}"
      _print "${description__fr}"
    end
  end

  def test_2

    dotest TestDefinition2, "nada\nnada"
  end

  #
  # TEST 3

  class TestDefinition3 < OpenWFE::ProcessDefinition
    description "nothing"
    description :lang => "es" do "nada" end
    sequence do
      _print "${description}"
      _print "${description__es}"
    end
  end

  def test_3

    dotest TestDefinition3, "nothing\nnada"
  end

  #
  # TEST 4

  def test_4

    @engine.register_participant :check do |fexp, wi|
      @tracer << fexp.lookup_variable('description').class.name
      @tracer << "\n"
    end

    dotest(
"""<process-definition name='test_1' revision='x'>
  <description language='en'>nothing</description>
  <description language='es'>nada</description>
  <sequence>
    <participant ref='check' />
    <print>${description}</print>
    <print>${description__en}</print>
    <print>${description__es}</print>
  </sequence>
</process-definition>""",
      "String\nnothing\nnothing\nnada")
  end

  #
  # TEST 5

  class Test5 < OpenWFE::ProcessDefinition
    description "nada"
    _print "${r:fei.expname} ${r:fei.expid}"
  end

  def test_5

    dotest(Test5, 'print 0.1')
  end

end

