
#
# testing ruote
#
# Tue Apr 20 12:32:44 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/storage_participant'


class FtWaitLoggerTest < Test::Unit::TestCase

  def teardown

    @engine.shutdown
    @engine.context.storage.purge!
  end

  def test_wait_logger

    @engine = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))

    sp = @engine.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.process_definition { alpha }

    wfid = @engine.launch(pdef)

    sleep 0.500

    sp.reply(sp.first)

    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end

  def test_wait_logger_seen

    @engine = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))

    #@engine.noisy = true

    pdef = Ruote.process_definition { }

    wfid = @engine.launch(pdef)

    sleep 0.500

    assert_equal 2, @engine.context.logger.instance_variable_get(:@seen).size

    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 0, @engine.context.logger.instance_variable_get(:@seen).size
  end
end

