
#
# testing ruote
#
# Wed Jul 21 13:37:59 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/local_participant'


class FtParticipantAcceptTest < Test::Unit::TestCase
  include FunctionalBase

  class MyParticipant
    include Ruote::LocalParticipant

    def initialize (opts)
      @opts = opts
    end

    def accept? (workitem)
      workitem.participant_name.match(@opts['filter'] || '.?')
    end

    def consume (workitem)
      @context.tracer << 'filtered:'
      @context.tracer << workitem.participant_name
      @context.tracer << "\n"
      reply(workitem)
    end
  end

  class MyOtherParticipant
    include Ruote::LocalParticipant

    def consume (workitem)
      @context.tracer << workitem.participant_name
      @context.tracer << "\n"
      reply(workitem)
    end
  end

  def test_participant_on_reply

    pdef = Ruote.process_definition do
      sequence do
        absolute
        aberrant
        aloof
        nada
      end
    end

    @engine.register_participant 'a.+', MyParticipant, 'filter' => '^ab'
    @engine.register_participant '.+', MyOtherParticipant

    #noisy

    assert_trace %w[ filtered:absolute filtered:aberrant aloof nada ], pdef
  end
end

