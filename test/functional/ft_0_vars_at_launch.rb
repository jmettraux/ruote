
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Sep 20 23:40:10 JST 2008
#

require File.dirname(__FILE__) + '/base'


class FtVarsAtLaunchTest < Test::Unit::TestCase
  include FunctionalBase

  class Test0 < OpenWFE::ProcessDefinition
    echo '${var0}'
  end

  def test_vars_at_launch
    assert_trace(
      Test0,
      'val0',
      :launch_opts => { :variables => { 'var0' => 'val0' } })
  end
end

