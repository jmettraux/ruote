
#
# Testing OpenWFEru (Ruote)
#
# John Mettraux at openwfe.org
#

require 'test/unit'
require 'rubygems'

%w{ lib test }.each do |path|
  path = File.expand_path(File.dirname(__FILE__) + '/../' + path)
  $:.unshift(path) unless $:.include?(path)
end

require 'openwfe/worklist/storelocks'
require 'openwfe/participants/store_participants'


class MockItem
  attr_reader :fei
  def initialize (fei)
    @fei = fei
  end
  def flow_expression_id
    @fei
  end
end

class StoreLockTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  def test_0

    store = OpenWFE::StoreWithLocks.new(OpenWFE::HashParticipant)

    wi0 = MockItem.new("fei")

    store.store.push(wi0)

    wi1 = store.get_and_lock("locker_a", "fei")

    assert_not_nil wi1
    assert_equal wi0.object_id, wi1.object_id

    assert_raise RuntimeError do
      wi2 = store.get_and_lock("locker_b", "fei")
    end

    assert_equal store.get_locker("fei"), "locker_a"

    assert_raise RuntimeError do
      store.release "locker_b", "fei"
    end

    store.release "locker_a", "fei"

    assert_nil store.get_locker("fei")
  end

  def test_1

    store = OpenWFE::StoreWithLocks.new(
      OpenWFE::HashParticipant,
      nil,
      :lock_max_age => "100")

    wi0 = MockItem.new("fei")

    store.store.push(wi0)

    wi1 = store.get_and_lock("locker_a", "fei")

    assert_not_nil wi1

    sleep 1

    assert_nil store.get_locker("fei")
  end

end

