
#
# testing ruote
#
# Mon Apr 19 14:38:54 JST 2010
#
# Qcon Tokyo, special day
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/local_participant'


class FtParticipantRejectTest < Test::Unit::TestCase
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

  def test_workitems_dispatching_message

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha, DifficultParticipant

    #noisy

    assert_trace(%w[ diff diff ], pdef)
  end
end

