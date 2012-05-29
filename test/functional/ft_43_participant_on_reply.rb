
#
# testing ruote
#
# Thu Apr 22 14:41:38 JST 2010
#

require File.expand_path('../base', __FILE__)

require 'ruote/part/local_participant'


class FtParticipantOnReplyTest < Test::Unit::TestCase
  include FunctionalBase

  class MyParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
    end
    def consume(workitem)
      reply(workitem)
    end
    def on_reply(workitem)
      workitem.fields['message'] = 'hello'
    end
  end

  def test_participant_on_reply

    pdef = Ruote.process_definition do
      sequence do
        alpha
        echo '${f:message}'
      end
    end

    @dashboard.register_participant :alpha, MyParticipant

    assert_trace('hello', pdef)
  end

  class AwkwardParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
    end
    def consume(workitem)
      reply(workitem)
    end
    def on_reply(workitem)
      return if workitem.fields['pass']
      raise 'something went wrong'
    end
  end

  def test_participant_on_reply_error

    pdef = Ruote.process_definition do
      sequence do
        alpha
        echo 'over.'
      end
    end

    @dashboard.register_participant :alpha, AwkwardParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    err = ps.errors.first
    err.fields['pass'] = true
    @dashboard.replay_at_error(err)

    wait_for(wfid)

    assert_equal 'over.', @tracer.to_s
  end

  class MyOtherParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
    end
    def consume(workitem)
      workitem.fields['message'] = (workitem.fields['message'] || '') * 2
      reply(workitem)
    end
    def on_apply(workitem)
      workitem.fields['message'] = 'hello'
    end
  end

  def test_participant_on_apply

    @dashboard.register :alpha, MyOtherParticipant

    pdef = Ruote.process_definition do
      sequence do
        alpha
        echo '${message}'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 'hellohello', @tracer.to_s
  end

  class MyOtherAwkwardParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
    end
    def consume(workitem)
      reply(workitem)
    end
    def on_apply(workitem)
      return if workitem.fields['pass']
      raise 'something went not right'
    end
  end

  def test_participant_on_apply_error

    @dashboard.register :alpha, MyOtherAwkwardParticipant

    pdef = Ruote.process_definition do
      sequence do
        alpha
        echo 'over.'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    err = ps.errors.first

    assert_equal 'apply', err.msg['action']

    err.fields['pass'] = true
    @dashboard.replay_at_error(err)

    r = wait_for(wfid)

    assert_equal 'terminated', r['action']

    assert_equal 'over.', @tracer.to_s
  end
end

