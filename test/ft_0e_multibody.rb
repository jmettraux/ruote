
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Nov  6 10:10:57 JST 2007
#

require 'flowtestbase'


class FlowTest0e < Test::Unit::TestCase
  include FlowTestBase

  def test_multi_body

    #log_level_to_debug

    dotest(
'''<process-definition name="n" revision="0">
  <print>ok</print>
  <print>nok</print>
</process-definition>''', "ok")
  end

end

