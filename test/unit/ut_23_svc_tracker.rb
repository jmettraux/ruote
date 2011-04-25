
#
# testing ruote
#
# Mon Apr 25 12:24:57 JST 2011
#
# in Singapore
#

require File.join(File.dirname(__FILE__), %w[ .. test_helper.rb ])

require 'ostruct'
require 'ruote'
require 'ruote/svc/tracker'


class UtSvcTrackerTest < Test::Unit::TestCase

  class FakeStorage
    def initialize
      @count = -1
    end
    def put(doc)
      @count = @count + 1
      return true if @count == 0
      nil
    end
    def get_trackers
      { 'trackers' => {} }
    end
  end

  # Fighting issue found by Pedro Texeira :
  #
  # http://groups.google.com/group/openwferu-users/browse_thread/thread/cf2546d0b1cebfe8
  #
  def test_add_tracker_fail_and_retry

    con = OpenStruct.new(:storage => FakeStorage.new)

    pl = Ruote::Tracker.new(con)

    pl.add_tracker('some-wfid', 'reply', 'some-id', {}, {})

    assert true
  end
end

