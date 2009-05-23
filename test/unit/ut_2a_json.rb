
#
# Testing ruote (OpenWFEru)
#
# Kenneth Kalmer at opensourcery.co.za
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/util/json'

begin
  require 'json'
  require 'activesupport'
rescue LoadError
  puts %q{This test case relies on the presence of the 'json' and 'activesupport' gems}
  exit 1
end

# This test case relies on the presence of the following gems:
#
#   * json
#   * activesupport
#
# Optionally, the yajl-ruby gem can also be installed
#
class TestJSON < Test::Unit::TestCase

  def setup
    %w{ @available_backends @proxy }.each do |ivar|
      OpenWFE::Json::Backend.instance_variable_set ivar, nil
    end
  end

  def test_loading_backends

    available_backends = OpenWFE::Json::Backend.available
    assert_kind_of Array, available_backends
    assert available_backends.size >= 2
  end

  def test_priorities

    map = OpenWFE::Json::Backend.priorities
    assert_equal [ 'JSON', 'ActiveSupport' ], map
  end

  def test_json_delegation

    json = OpenWFE::Json::Backend.delegates['JSON']

    assert_equal json[:encode], 'dump'
    assert_equal json[:decode], 'parse'
  end

  def test_active_support_delegation

    as = OpenWFE::Json::Backend.delegates['ActiveSupport']

    assert_equal as[:encode], 'encode'
    assert_equal as[:decode], 'decode'
  end

  def test_loading_backend_proxy

    proxy = OpenWFE::Json::Backend.proxy
    assert_equal proxy.backend, 'JSON'
    assert_respond_to proxy, 'encode'
    assert_respond_to proxy, 'decode'
  end

  def test_setting_backends

    OpenWFE::Json::Backend.prefered = 'ActiveSupport'
    assert_equal OpenWFE::Json::Backend.proxy.backend, 'ActiveSupport'
  end

  def test_setting_backends_unknown

    OpenWFE::Json::Backend.instance_variable_set '@available_backends', ['JSON', 'ActiveSupport']
    OpenWFE::Json::Backend.prefered = 'Yajl'

    assert_equal 'JSON', OpenWFE::Json::Backend.proxy.backend
  end

  def test_failing_with_no_backends

    OpenWFE::Json::Backend.instance_variable_set '@available_backends', []
    assert_raise LoadError do
      OpenWFE::Json::Backend.proxy
    end
  end

  def test_encoding

    OpenWFE::Json::Backend.available.each do |backend|

      OpenWFE::Json::Backend.prefered = backend

      assert_equal OpenWFE::Json::Backend.proxy.backend, backend

      assert_nothing_raised "Error encoding with '#{backend}' backend" do
        assert_equal OpenWFE::Json.encode({}), '{}'
      end
    end
  end

  def test_decoding

    OpenWFE::Json::Backend.available.each do |backend|

      OpenWFE::Json::Backend.prefered = backend

      assert_equal OpenWFE::Json::Backend.proxy.backend, backend

      assert_nothing_raised "Error decoding with '#{backend}' backend" do
        assert_equal OpenWFE::Json.decode('{}'), {}
      end
    end
  end

end
