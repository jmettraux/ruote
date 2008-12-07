
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require 'openwfe/participants'

require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest38c < Test::Unit::TestCase
  include FlowTestBase

  #
  # test 5
  #

  class TestTag5 < OpenWFE::ProcessDefinition

    sequence do
      sub0
    end

    process_definition :name => "sub0" do
      sequence :tag => "seq0" do
        peekin
      end
    end
  end

  def test_5

    @engine.register_participant :peekin do |fexp, wi|

      wfid = fexp.fei.parent_workflow_instance_id

      assert_equal 3, @engine.get_variables(wfid).size
        # :next_sub_id and one [sub] process definition

      assert_equal 0, @engine.process_status(wfid).tags.size
      assert_equal "", @engine.process_status(wfid).tags.to_s

      @tracer << "peekin\n"
    end

    dotest TestTag5, "peekin"
  end


  #
  # test 5b
  #

  class TestTag5b < OpenWFE::ProcessDefinition

    sequence do
      sub0
    end

    process_definition :name => "sub0" do
      sequence :tag => "/seq0" do
        peekin
      end
    end
  end

  def test_5b

    @engine.register_participant :peekin do |fexp, wi|

      wfid = fexp.fei.parent_workflow_instance_id

      #p @engine.get_variables(wfid).keys
      assert_equal 4, @engine.get_variables(wfid).size
        # :next_sub_id and one [sub] process definition (and the tag)

      #p @engine.process_status(wfid).tags
      assert_equal [ 'seq0' ], @engine.process_status(wfid).tags

      @tracer << 'peekin'
    end

    dotest TestTag5b, 'peekin'
  end

end

