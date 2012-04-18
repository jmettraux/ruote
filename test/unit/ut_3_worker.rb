
#
# testing ruote
#
# Tue Oct 11 21:15:41 JST 2011
#

require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../../functional/storage_helper', __FILE__)

require 'ruote'


class UtWorkerTest < Test::Unit::TestCase

  class StorageA < Ruote::HashStorage
    attr_accessor :caller
    def get_msgs
      @caller = :nemo
      []
    end
  end
  class StorageB < StorageA
    def get_msgs(worker)
      @caller = worker
      []
    end
  end

  def test_get_msgs

    storage = StorageA.new
    worker = Ruote::Worker.new(storage)

    assert_nil storage.caller
    worker.send(:step)
    assert_equal :nemo, storage.caller
  end

  def test_get_msgs_with_worker_name

    storage = StorageB.new
    worker = Ruote::Worker.new(storage)

    assert_nil storage.caller
    worker.send(:step)
    assert_equal worker, storage.caller
  end

  class StorageX < Ruote::HashStorage
    def get_msgs
      raise('failing...')
    end
  end

  def test_step_error_interception

    $err = nil

    worker = Ruote::Worker.new(StorageX.new)
    def worker.handle_step_error(e, msg)
      $err = e
    end

    worker.send(:step)

    assert_equal 'failing...', $err.message
  end
end

