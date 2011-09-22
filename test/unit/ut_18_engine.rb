
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


class UtEngineTest < Test::Unit::TestCase

  def test_initialize_with_worker

    storage = determine_storage({})
    worker = Ruote::Worker.new(storage)
    engine = Ruote::Engine.new(worker, false)
  end

  def test_initialize_with_worker_and_without_logger

    storage = determine_storage({})
    worker = Ruote::Worker.new(storage)
    engine = Ruote::Engine.new(worker, false)
  end

  def test_initialize_with_storage

    storage = determine_storage({})
    engine = Ruote::Engine.new(storage)
  end

  def test_initialize_storage_without_logger

    storage = determine_storage({})
    engine = Ruote::Engine.new(storage)
  end
end

