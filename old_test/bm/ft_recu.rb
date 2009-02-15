
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/def'

require File.dirname(__FILE__) + '/flowtestbase'


class FlowTestRecursion < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  #
  # test 0
  #

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      #print_i
      #subprocess :ref => "Test"
      subprocess :ref => "Testy"
    end
    process_definition :name => "Testy" do
      sequence do
        print_i
        subprocess :ref => "Testy"
      end
      #_loop do
      #  print_i
      #end
    end
  end

  def test_0

    i = 0
    last = Time.now.to_f

    @engine.register_participant :print_i do
      now = Time.now.to_f
      print "#{i}"
      if i % 10 == 0
        print "("
        print "#{now-last}"
        print " #{@engine.get_expression_storage.size}"
        print ")"
      end
      print " "
      last = now
      i += 1
    end

    #dotest TestTag0, "blah"
    @engine.launch Test0

    sleep 360
  end

end

