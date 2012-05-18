
#
# testing ruote
#
# Fri Apr 22 15:44:38 JST 2011
#
# Singapore
#

require File.expand_path('../base', __FILE__)


class FtParticipantCodeTest < Test::Unit::TestCase
  include FunctionalBase

  def test_block_participant

    @dashboard.context['participant_in_variable_enabled'] = true

    pdef = Ruote.process_definition :name => 'def0' do

      set 'v:alpha' => {
        'on_workitem' => lambda { |wi|
          wi.fields['alpha'] = wi.participant_name
          wi.fields['x'] = 0
        }
      }

      alpha
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal(
      { 'alpha' => 'alpha', 'x' => 0, '__result__' => 0 },
      r['workitem']['fields'])
  end

  def test_code_participant

    @dashboard.context['participant_in_variable_enabled'] = true

    pdef = Ruote.process_definition do

      set 'v:alpha' => %{
        def consume(workitem)
          workitem.fields['x'] = 0
          workitem.fields['alpha'] = workitem.participant_name
          reply_to_engine(workitem)
        end
      }

      alpha
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal(
      { 'x' => 0, 'alpha' => 'alpha' },
      r['workitem']['fields'])
  end
end

