
#
# testing ruote
#
# Wed Jun 29 07:42:42 JST 2011
#

require File.join(File.dirname(__FILE__), 'base')


class FtStash < Test::Unit::TestCase
  include FunctionalBase

  class SolParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << stash_get(fexp.root_id, 'lost')
      @context.tracer << "\n" + (get('lost') || 'nada')
      reply
    end
  end

  def test_stash_on_launch

    @engine.register { sally SolParticipant }

    #@engine.noisy = true

    wfid = @engine.launch(Ruote.define do
      sally
    end,
    {}, # workitem fields
    {}, # process variables
    { 'lost' => 'wallet' }) # root stash

    r = @engine.wait_for(wfid)

    assert_equal "wallet\nnada", @tracer.to_s
  end
end

