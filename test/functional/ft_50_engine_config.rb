
#
# testing ruote
#
# Mon Dec  6 10:40:29 JST 2010
#

require File.expand_path('../base', __FILE__)


class FtEngineConfigTest < Test::Unit::TestCase
  include FunctionalBase

  def test_engine_config

    @dashboard.configure('a', 'b')

    assert_equal 'b', @dashboard.configuration('a')
    assert_equal 'b', @dashboard.storage.get_configuration('engine')['a']
  end
end

