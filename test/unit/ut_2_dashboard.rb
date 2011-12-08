
#
# testing ruote
#
# Sun Jan  3 12:04:07 JST 2010
#
# Matt Nichols (http://github.com/mattnichols)
#

require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../../functional/storage_helper', __FILE__)

require 'ruote'


class UtDashboardTest < Test::Unit::TestCase

  def teardown
    @dashboard.shutdown
  end

  def test_initialize_with_worker

    storage = determine_storage({})
    worker = Ruote::Worker.new(storage)
    @dashboard = Ruote::Dashboard.new(worker, false)
  end

  def test_initialize_with_worker_and_without_logger

    storage = determine_storage({})
    worker = Ruote::Worker.new(storage)
    @dashboard = Ruote::Dashboard.new(worker, false)
  end

  def test_initialize_with_storage

    storage = determine_storage({})
    @dashboard = Ruote::Dashboard.new(storage)
  end

  def test_initialize_storage_without_logger

    storage = determine_storage({})
    @dashboard = Ruote::Dashboard.new(storage)
  end

  def test_initialize_and_run_no_worker

    @dashboard = Ruote::Dashboard.new(
      Ruote::Worker.new(
        Ruote::HashStorage.new),
      false)

    assert_nil @dashboard.context.worker.run_thread
  end

  def test_initialize_and_run_worker

    @dashboard = Ruote::Dashboard.new(
      Ruote::Worker.new(
        Ruote::HashStorage.new))

    assert_not_nil @dashboard.context.worker.run_thread
  end

  def test_initialize_and_run_no_workers

    @dashboard = Ruote::Dashboard.new(
      Ruote::Worker.new(
        'bravo',
        Ruote::Worker.new(
          'alpha',
          Ruote::HashStorage.new)),
      false)

    assert @dashboard.context.keys.include?('s_alpha_worker')
    assert @dashboard.context.keys.include?('s_bravo_worker')

    assert_nil @dashboard.context.alpha_worker.run_thread
    assert_nil @dashboard.context.bravo_worker.run_thread
  end

  def test_initialize_and_run_workers

    @dashboard = Ruote::Dashboard.new(
      Ruote::Worker.new(
        'bravo',
        Ruote::Worker.new(
          'alpha',
          Ruote::HashStorage.new)))

    assert_not_nil @dashboard.context.alpha_worker.run_thread
    assert_not_nil @dashboard.context.bravo_worker.run_thread
  end

  def test_join_when_no_worker

    @dashboard = Ruote::Dashboard.new(determine_storage({}))

    @dashboard.join

    assert true
  end

  def test_context__dashboard_engine

    @dashboard = Ruote::Dashboard.new(determine_storage({}))

    assert_equal @dashboard, @dashboard.context.engine
    assert_equal @dashboard, @dashboard.context.dashboard
  end
end

