
#
# testing ruote
#
# Thu Dec 24 18:05:39 JST 2009
#

require File.expand_path('../base', __FILE__)


class FtAddServiceTest < Test::Unit::TestCase
  include FunctionalBase

  class MyService

    attr_reader :context, :options

    def initialize(context, options={})

      @context = context
      @options = options
    end
  end

  def test_as_path_class

    @dashboard.add_service('toto', 'ruote', 'FtAddServiceTest::MyService')

    assert_equal MyService, @dashboard.context.toto.class
  end

  def test_as_instance

    @dashboard.add_service('toto', MyService.new(nil))

    assert_equal MyService, @dashboard.context.toto.class
  end

  def test_as_class

    @dashboard.add_service('toto', MyService)

    assert_equal MyService, @dashboard.context.toto.class
  end

  def test_as_path_class_options

    @dashboard.add_service(
      'toto', 'ruote', 'FtAddServiceTest::MyService', 'colour' => 'blue')

    assert_equal MyService, @dashboard.context.toto.class
    assert_equal 'blue', @dashboard.context.toto.options['colour']
  end

  def test_add_service_returns_service

    toto = @dashboard.add_service(
      'toto', 'ruote', 'FtAddServiceTest::MyService', 'colour' => 'blue')

    assert_equal MyService, toto.class
  end

  # Fighting https://github.com/jmettraux/ruote/issues/28
  #
  def test_add_history

    assert_equal Ruote::DefaultHistory, @dashboard.context.history.class

    @dashboard.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    assert_equal Ruote::StorageHistory, @dashboard.context.history.class

    engine = Ruote::Engine.new(@dashboard.storage)

    assert_equal Ruote::StorageHistory, engine.context.history.class
  end

  # Fighting https://github.com/jmettraux/ruote/issues/28
  #
  def test_add_history

    assert_equal Ruote::DefaultHistory, @dashboard.history.class

    @dashboard.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    assert_equal Ruote::StorageHistory, @dashboard.history.class

    engine = Ruote::Engine.new(@dashboard.storage)

    assert_equal Ruote::StorageHistory, engine.history.class
  end

  # Fighting https://github.com/jmettraux/ruote/issues/28
  #
  def test_add_history_and_log

    #@dashboard.noisy = true

    #previous_history = @dashboard.history

    @dashboard.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    @dashboard.storage.put_msg('noop', 'nada' => true)

    sleep 0.500

    assert_equal(
      'noop', @dashboard.history.by_date(Time.now.utc.to_s).first['action'])
  end
end

