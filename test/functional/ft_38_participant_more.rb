
#
# testing ruote
#
# Mon Apr 19 14:38:54 JST 2010
#
# Qcon Tokyo, special day
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/local_participant'


class FtParticipantMoreTest < Test::Unit::TestCase
  include FunctionalBase

  class DifficultParticipant
    include Ruote::LocalParticipant
    def initialize (opts)
    end
    def consume (workitem)
      context.tracer << "diff\n"
      if workitem.fields['rejected'].nil?
        workitem.fields['rejected'] = true
        reject(workitem)
      else
        reply_to_engine(workitem)
      end
    end
  end

  class FightingParticipant
    include Ruote::LocalParticipant
    def initialize (opts)
    end
    def consume (workitem)
      try = workitem.fields['try'] || 0
      context.tracer << "try#{try}\n"
      workitem.fields['try'] = try + 1
      if (try == 0)
        re_apply(workitem)
      else
        reply(workitem)
      end
    end
  end

  def test_participant_reject

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha, DifficultParticipant

    #noisy

    assert_trace(%w[ diff diff ], pdef)
  end

  def test_participant_re_apply

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha, FightingParticipant

    #noisy

    assert_trace(%w[ try0 try1 ], pdef)
  end
end

