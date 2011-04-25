
#
# testing ruote
#
# Fri Apr 22 15:44:38 JST 2011
#
# Singapore
#

require File.join(File.dirname(__FILE__), 'base')


class FtParticipantCodeTest < Test::Unit::TestCase
  include FunctionalBase

  # ~~~ this is ruby-centric !!!

  # if there is 'on_workitem', then it's a participant

  def test_participant_code_in_var

    pdef = Ruote.process_definition :name => 'def0' do

      set 'v:alpha' => %{
        workitem.fields['x'] = 0
      }
      set 'v:bravo' => %{
        lambda { |wi| wi.fields['y'] = 1 }
      }
      set 'v:charly' => lambda { |wi|
        wi.fields['z'] = 2
      }
      #set 'v:delta' => %{
      #  def consume(wi)
      #  end
      #  def cancel(fei, flavour)
      #  end
      #}
      #define 'v:delta' do
      #  def consume(workitem)
      #  end
      #end
      #participant 'delta' do
      #end

      alpha
      bravo
      charly
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(wfid)

    assert_equal(
      { 'x' => 0, 'y' => 1, 'z' => 2, '__result__' => 2 },
      r['workitem']['fields'])
  end
end

