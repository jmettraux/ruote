
#
# testing ruote
#
# Wed Jun 29 07:42:42 JST 2011
#

require File.expand_path('../base', __FILE__)


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

    @dashboard.register { sally SolParticipant }

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      sally
    end,
    {}, # workitem fields
    {}, # process variables
    { 'lost' => 'wallet' }) # root stash

    r = @dashboard.wait_for(wfid)

    assert_equal "wallet\nnada", @tracer.to_s
  end
end

