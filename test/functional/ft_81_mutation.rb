
#
# testing ruote
#
# Tue Oct 30 06:52:44 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtMutationTest < Test::Unit::TestCase
  include FunctionalBase

  def test_mutation_in_sequence

    #
    # prepare workflow execution to mutate

    @dashboard.register do
      sam Ruote::StorageParticipant
      nick Ruote::NoOpParticipant
    end

    pdef0 = Ruote.define do
      nick
      nick
      sam
    end

    wfid = @dashboard.launch(pdef0)
    3.times { @dashboard.wait_for('dispatched') }

    #
    # compute mutations

    # adding at the end of the sequence

    pdef1 = Ruote.define do
      nick
      nick
      sam
      nick
    end

    mutation = @dashboard.compute_mutation(wfid, pdef1)
    h = mutation.to_h

    assert_equal(1, h.size)
    assert_equal(0, Ruote.extract_child_id(h.keys.first))
    assert_equal('update', h.values.first['action'])
    assert_equal(pdef1, h.values.first['tree'])

    # shrinking the sequence

    pdef1 = Ruote.define do
      sam
    end

    mutation = @dashboard.compute_mutation(wfid, pdef1)
    h = mutation.to_h

    assert_equal(1, h.size)
    assert_equal(0, Ruote.extract_child_id(h.keys.first))
    assert_equal('re-apply', h.values.first['action'])
    assert_equal(pdef1, h.values.first['tree'])
  end
end

