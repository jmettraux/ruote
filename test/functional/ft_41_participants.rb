
#
# testing ruote
#
# Mon Jun 14 12:02:53 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/local_participant'


class FtParticipantsTest < Test::Unit::TestCase
  include FunctionalBase

  class MyParticipant
    include Ruote::LocalParticipant
    def consume (workitem)
      workitem.fields['seen'] = true
      reply_to_engine(workitem)
    end
  end

  class MyMessageParticipant
    include Ruote::LocalParticipant
    def initialize (opts)
      @opts = opts
    end
    def consume (workitem)
      workitem.fields['message'] = @opts['message']
      reply_to_engine(workitem)
    end
  end

  def test_participant_without_initialize

    @engine.register_participant :alpha, MyParticipant

    #noisy

    wfid = @engine.launch(Ruote.process_definition do
      alpha
    end)

    r = wait_for(wfid)

    assert_equal true, r['workitem']['fields']['seen']
  end

  def test_participant_with_initialize

    @engine.register_participant :bravo, MyMessageParticipant, 'message' => 'hi'

    #noisy

    wfid = @engine.launch(Ruote.process_definition do
      bravo
    end)

    r = wait_for(wfid)

    assert_equal 'hi', r['workitem']['fields']['message']
  end

  class MyOtherParticipant
    include Ruote::LocalParticipant
    def consume (wi)
      wi.fields['hello'] = 'kitty'
      reply_to_engine(wi)
    end
    def on_reply (wi)
      @context.tracer << wi.fields['hello'] + "\n"
      @context.tracer << applied_workitem(wi.fei).fields['hello'] + "\n"
      @context.tracer << workitem(wi.fei).fields['hello']
    end
  end

  def test_workitem_method

    @engine.register 'alpha', MyOtherParticipant

    #noisy

    wfid = @engine.launch(Ruote.define { alpha }, 'hello' => 'world')

    @engine.wait_for(wfid)

    assert_equal %w[ kitty world world ], @tracer.to_a
  end
end

