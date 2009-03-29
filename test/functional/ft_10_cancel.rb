
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Mar 29 13:09:36 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtCancelTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cancel_missing_process

    assert_raise(RuntimeError) {
      @engine.cancel_process('missing')
    }
  end
end

