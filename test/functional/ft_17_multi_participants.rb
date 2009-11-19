
#
# Testing Ruote (OpenWFEru)
#
# Thu Nov 19 21:34:43 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtMultiParticipants < Test::Unit::TestCase
  include FunctionalBase

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      alpha
    end
  end

  class ::OpenWFE::MultiParticipant
    include ::OpenWFE::LocalParticipant

    def initialize (*participants)

      @participants = participants

      # neuter all participant except the first

      @participants[1..-1].each do |pa|
        class << pa
          def reply_to_engine (workitem)
            # silent
          end
        end
      end
    end

    def application_context= (c)

      @application_context = c

      @participants.first.application_context = c \
        if @participants.first.respond_to?(:application_context=)
    end

    def consume (workitem)

      @participants.each { |pa| pa.consume(workitem) }
    end

    def cancel (cancelitem)

      @participants.each { |pa| pa.cancel(cancelitem) }
    end
  end

  def test_multi_participant

    @engine.register_participant(
      :alpha,
      OpenWFE::MultiParticipant.new(
        OpenWFE::BlockParticipant.new { |wi| @tracer << "A received wi\n" },
        OpenWFE::BlockParticipant.new { |wi| @tracer << "B received wi\n" }))

    assert_trace Test0, "A received wi\nB received wi"
  end
end

