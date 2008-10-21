
#
# Testing Ruote
#
# John Mettraux at openwfe.org
#
# Tue Oct 21 10:17:33 JST 2008
#

require 'rubygems'

require 'openwfe/def'
require 'flowtestbase'


class FlowTest14d < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sub0
    process_definition 'sub0' do
      part0
    end
  end

  def test_0

    #log_level_to_debug

    infei = nil

    @engine.register_participant('part0') do |wi|
      infei = wi.fei.dup
    end

    fei = @engine.launch(Test0)

    sleep 0.350

    #puts infei.to_s
    #puts fei.to_s
    assert_not_equal 'no-url', fei.wfurl
    assert_equal fei.wfurl, infei.wfurl
  end

end

