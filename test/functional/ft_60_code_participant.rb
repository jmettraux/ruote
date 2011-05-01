
#
# testing ruote
#
# Tue Apr 26 03:30:29 JST 2011
#
# between Changi and Haneda (JA622A)
#

require File.join(File.dirname(__FILE__), 'base')


class FtCodeParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitems_dispatching_message

    pdef = Ruote.process_definition do
      set 'v:alpha' => '''
        def consume(wi)
          context.tracer << "#{wi.participant_name}\n"
        end
        def cancel(wi)
          context.tracer << "cancelled\n"
        end
      '''
      alpha
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    #@engine.wait_for(:alpha)

    sleep 1
    assert_not_equal '', @tracer.to_s
  end
end

