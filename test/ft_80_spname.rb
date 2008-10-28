
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Fri Jan  4 15:00:26 JST 2008
#
# Fighting bug #16791
# http://rubyforge.org/tracker/index.php?func=detail&aid=16791&group_id=2609&atid=10023
#

require 'flowtestbase'


class FlowTest80 < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #

  class Def0 < OpenWFE::ProcessDefinition
    sequence do
      subprocess :ref => "last_step"
      last_step
    end
    process_definition :name => "last_step" do
      _print "last_step"
    end
  end

  def test_0
    dotest Def0, ([ "last_step" ] * 2).join("\n")
  end

  TEST0B = %{
    <process-definition name="def" revision="0b">
      <sequence>
        <subprocess ref="last_step" />
        <last_step />
      </sequence>
      <process-definition name="last_step">
        <print>last_step</print>
      </process-definition>
    </process-definition>
  }.strip

  def test_0b
    dotest TEST0B, ([ "last_step" ] * 2).join("\n")
  end

  #
  # Test 1
  #
  # Checking with participants
  #

  class Def1 < OpenWFE::ProcessDefinition
    sequence do
      mister_alpha
      participant :ref => :mister_alpha
      participant :ref => "mister_alpha"
      #participant :ref => "mister-alpha"
      mister_bravo
      #participant :ref => :mister_bravo
      #participant :ref => "mister_bravo"
      participant :ref => "mister-bravo"
    end
  end

  def test_1

    @engine.register_participant :mister_alpha do
      @tracer << "alpha\n"
    end
    @engine.register_participant "mister-bravo" do
      @tracer << "bravo\n"
    end

    dotest Def1, ([ "alpha" ] * 3 + [ "bravo" ] * 2).join("\n")
  end

end

