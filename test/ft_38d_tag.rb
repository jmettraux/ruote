
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Thu Jul 24 17:44:11 JST 2008
#

require 'flowtestbase'

require 'openwfe/def'


class FlowTest38d < Test::Unit::TestCase
  include FlowTestBase

  #
  # test 0
  #

  class Test0 < OpenWFE::ProcessDefinition
    sequence :tag => 'approve' do
      bob
      concurrence do
        reserve :mutex => 'poprocessing' do
          petia
        end
        reserve :mutex => 'poprocessing' do
          alpha
        end
      end
      _redo :ref => 'approve'
    end
  end

  def test_0

    #log_level_to_debug

    @engine.register_participant "bob" do
      @tracer << "bob"
    end
    @engine.register_participant "petia" do
      @tracer << "petia"
    end
    @engine.register_participant "alpha" do |workitem|
      @tracer << "alpha"
    end

    @engine.launch Test0

    sleep 1

    assert (@tracer.to_s.length > 10)
  end

end

