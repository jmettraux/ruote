
#
# testing ruote
#
# Wed Jan 26 09:21:06 JST 2011
#

require File.join(File.dirname(__FILE__), %w[ .. test_helper.rb ])
#require File.join(File.dirname(__FILE__), %w[ .. functional storage_helper.rb ])

require 'ostruct'
require 'ruote'
require 'ruote/svc/participant_list'


class UtEngineTest < Test::Unit::TestCase

  class FakeStorage
    def initialize
      @count = -1
    end
    def put (doc)
      @count = @count + 1
      return true if @count == 0
      nil
    end
    def get_configuration (whatever)
      { 'list' => [] }
    end
  end

  # Fighting issue #20 found by 'sandbox'
  #
  # https://github.com/jmettraux/ruote/issues#issue/20
  #
  def test_register_participant_fail_and_retry

    con = OpenStruct.new(:storage => FakeStorage.new)

    pl = Ruote::ParticipantList.new(con)

    pl.register('toto', Ruote::NullParticipant, { :hello => :world }, nil)

    assert true
  end
end

