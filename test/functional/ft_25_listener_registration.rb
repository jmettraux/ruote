
#
# Testing Ruote (OpenWFEru)
#
# Wed Aug 12 23:24:16 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtListenerRegistrationTest < Test::Unit::TestCase
  include FunctionalBase

  def test_register_listener

    #noisy

    #@engine.register_participant :alpha do |workitem|
    #  @tracer << 'alpha'
    #end
    #sleep 0.001
    #entry = logger.log.last
    #assert_equal :registered, entry[1]
    #assert_equal :alpha, entry.last[:regex]
    #assert_equal Ruote::BlockParticipant, entry.last[:participant].class
    #assert_equal [ /^alpha$/ ], @engine.plist.list.collect { |e| e.first }
  end
end

