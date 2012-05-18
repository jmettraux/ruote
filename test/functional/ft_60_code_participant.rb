
#
# testing ruote
#
# Tue Apr 26 03:30:29 JST 2011
#
# between Changi and Haneda (JA622A)
#

require File.expand_path('../base', __FILE__)


class FtCodeParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant_in_vars_not_enabled

    pdef = Ruote.process_definition do
      set 'v:alpha' => '''
        def consume(wi)
          context.tracer << "#{wi.participant_name}\n"
        end
        def cancel(fei, flavour)
          context.tracer << "cancelled\n"
        end
      '''
      alpha
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
  end

  def test_workitems_dispatching_message

    @dashboard.context['participant_in_variable_enabled'] = true

    pdef = Ruote.process_definition do
      set 'v:alpha' => '''
        def consume(wi)
          context.tracer << "#{wi.participant_name}\n"
        end
        def cancel(fei, flavour)
          context.tracer << "cancelled\n"
        end
      '''
      alpha
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)
    @dashboard.wait_for(1)

    assert_equal 'alpha', @tracer.to_s

    @dashboard.cancel(wfid)
    @dashboard.wait_for(wfid)

    assert_equal "alpha\ncancelled", @tracer.to_s
  end
end

