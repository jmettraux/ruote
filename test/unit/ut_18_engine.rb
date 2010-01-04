
#
# testing ruote
#
# Sun Jan  3 12:04:07 JST 2010
#
# Matt Nichols (http://github.com/mattnichols)
#

require File.join(File.dirname(__FILE__), %w[ .. test_helper.rb ])
require File.join(File.dirname(__FILE__), %w[ .. functional storage_helper.rb ])

require 'ruote'


class UtEngineTest < Test::Unit::TestCase

  def test_initialize_with_worker

    storage = determine_storage(
      's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ])
    worker = Ruote::Worker.new(storage)
    engine = Ruote::Engine.new(worker, false)
  end

  def test_initialize_with_worker_and_without_logger

    storage = determine_storage({})
    worker = Ruote::Worker.new(storage)
    engine = Ruote::Engine.new(worker, false)
  end

  def test_initialize_with_storage

    storage = determine_storage(
      's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ])

    engine = Ruote::Engine.new(storage)
  end

  def test_initialize_storage_without_logger

    storage = determine_storage({})
    engine = Ruote::Engine.new(storage)
  end
end

