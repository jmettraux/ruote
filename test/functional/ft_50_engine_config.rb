
#
# testing ruote
#
# Mon Dec  6 10:40:29 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')


class FtEngineConfigTest < Test::Unit::TestCase
  include FunctionalBase

  def test_engine_config

    @engine.configure('a', 'b')

    assert_equal 'b', @engine.configuration('a')
    assert_equal 'b', @engine.storage.get_configuration('engine')['a']
  end
end

