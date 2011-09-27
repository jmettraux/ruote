
#
# testing ruote
#
# Fri Nov 13 10:30:32 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'

#
# testing forced rewinding
#
class FtCursorRewindTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cursor_forced_back

    pdef = Ruote.process_definition do
      cursor do
        alpha
        bravo
        charly
      end
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant
    bravo = @dashboard.register_participant :bravo, Ruote::StorageParticipant
    charly = @dashboard.register_participant :charly, Ruote::StorageParticipant

    #noisy

    #
    # reaching initial situation...

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    alpha.proceed(alpha.first)
    wait_for(:bravo)

    #
    # rewinding...

    wi = bravo.first
    wi.fields['__command__'] = [ 'back', 2 ]

    @dashboard.reply(wi)

    #
    # workitem is back to alpha

    wait_for(:alpha)
  end

  def test_cursor_forced_jump

    pdef = Ruote.process_definition do
      cursor do
        alpha
        bravo
        charly
      end
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    @dashboard.register_participant :bravo, Ruote::StorageParticipant
    sto = @dashboard.register_participant :charly, Ruote::StorageParticipant

    #noisy

    #
    # reaching initial situation...

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    sto.proceed(sto.first)
    wait_for(:bravo)

    #
    # rewinding...

    wi = sto.first

    exp = @dashboard.process(wfid).expressions.find { |e| e.name == 'cursor' }
    wi.h['fei'] = exp.h.fei
    wi.fields['__command__'] = [ 'jump', 'alpha' ]
      #
      # passing the "jump alpha" command to the cursor directly

    @dashboard.reply(wi)

    #
    # workitem is back to alpha

    wait_for(:alpha)
  end
end

