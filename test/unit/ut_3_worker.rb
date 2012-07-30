
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
      @caller = Thread.current['ruote_worker']
      []
    end
  end

  def test_get_msgs

    storage = StorageA.new
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

  def test_handle_step_error

    $err = nil

    worker = Ruote::Worker.new(StorageX.new)
    def worker.handle_step_error(e, msg)
      $err = e
    end

    worker.send(:step)

    assert_equal 'failing...', $err.message
  end
end

