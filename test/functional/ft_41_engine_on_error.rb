
#
# testing ruote
#
# Tue Jun  1 15:06:09 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/local_participant'


class FtEngineOnErrorTest < Test::Unit::TestCase
  include FunctionalBase

  class MyParticipant
    include Ruote::LocalParticipant
    def initialize (opts)
    end
    def consume (workitem)
      self.class.workitems << workitem
      reply(workitem)
    end
    def self.workitems
      (@workitems ||= [])
    end
  end

  def test_on_error

    pdef = Ruote.process_definition do
      sequence do
        bravo
      end
    end

    @engine.register_participant :alpha, MyParticipant
    @engine.on_error = :alpha

    assert_equal 0, MyParticipant.workitems.size

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    assert_equal 1, MyParticipant.workitems.size
    assert_nil @engine.process(wfid)

    assert_not_nil MyParticipant.workitems.first.fields['__error__']
  end

  def test_on_error_neutralized

    pdef = Ruote.process_definition :on_error => '' do
      bravo
    end

    @engine.register_participant :alpha, MyParticipant
    @engine.on_error = :alpha

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size
    assert_match /unknown expression 'bravo'/, ps.errors.first.message
  end
end

