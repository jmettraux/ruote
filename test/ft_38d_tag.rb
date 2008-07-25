
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
    sequence do
      concurrence do
        reserve :mutex => 'poprocessing' do
          petia
        end
        reserve :mutex => 'poprocessing' do
          alpha
        end
      end
      reserve :mutex => 'poprocessing' do
        alpha
      end
    end
  end

  def test_0

    #log_level_to_debug

    @engine.register_participant "petia" do
      @tracer << "petia\n"
    end
    @engine.register_participant "alpha" do |workitem|
      @tracer << "alpha\n"
    end

    dotest Test0, %w{ petia alpha alpha }.join("\n")
  end

end

