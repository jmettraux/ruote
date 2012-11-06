
#
# testing ruote
#
# Tue Oct 30 06:52:44 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtComputeMutationTest < Test::Unit::TestCase

  #
  # use a transient engine to test the mutation computation

  def setup

    @dash = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))

    @dash.register do
      sam Ruote::StorageParticipant
      nick Ruote::NoOpParticipant
    end
  end

  def teardown

    @dash.shutdown
  end

  def pprint(t0, t1, hmutations)

    puts
    puts '>' + '-' * 79
    p t0
    p t1
    pp hmutations
    puts '<' + '-' * 79
  end

  def print_header

    return unless ENV['NOISY'] == 'true'

    puts "\n" + "'" * `stty size`.strip.split(' ').last.to_i
    puts caller[1]
    puts
  end

  #
  # the tests themselves

  #
  # sequence testing

  def launch_nick_nick_sam_sequence

    print_header

    @pdef = Ruote.define do
      nick
      nick
      sam
    end

    @wfid = @dash.launch(@pdef)
    3.times { @dash.wait_for('dispatched') }
  end

  def test_sequence_same_tree

    launch_nick_nick_sam_sequence

    pdef1 = Ruote.define do
      nick
      nick
      sam
    end

    mutation = @dash.compute_mutation(@wfid, pdef1)
    h = mutation.to_h

    #pprint(@pdef, pdef1, h)
    assert_equal(0, h.size)
  end

  def test_sequence_change_post_child

    launch_nick_nick_sam_sequence

    pdef1 = Ruote.define do
      nick
      nick
      sam
      nick
    end

    mutation = @dash.compute_mutation(@wfid, pdef1)
    h = mutation.to_h

    #pprint(@pdef, pdef1, h)
    assert_equal(1, h.size)
    assert_equal(0, Ruote.extract_child_id(h.keys.first))
    assert_equal('update', h.values.first['action'])
    assert_equal(pdef1, h.values.first['tree'])
  end

  def test_sequence_change_pre_child

    launch_nick_nick_sam_sequence

    pdef1 = Ruote.define do
      nick
      sam
      sam
    end

    mutation = @dash.compute_mutation(@wfid, pdef1)
    h = mutation.to_h

    #pprint(@pdef, pdef1, h)
    assert_equal(1, h.size)
    assert_equal(0, Ruote.extract_child_id(h.keys.first))
    assert_equal('re-apply', h.values.first['action'])
    assert_equal(pdef1, h.values.first['tree'])
  end

  def test_deeper_sequence

    print_header

    pdef0 = Ruote.define do
      nick
      sequence do
        nick
        sam
      end
      nick
    end

    wfid = @dash.launch(pdef0)
    3.times { @dash.wait_for('dispatched') }

    ps = @dash.ps(wfid)

    pdef1 = Ruote.define do
      nick
      sequence do
        nick
        hector
      end
      nick
    end

    mutation = @dash.compute_mutation(wfid, pdef1)
    h = mutation.to_h

    #pprint(pdef0, pdef1, h)
    assert_equal(1, h.size)
    assert_equal('0_1_1', h.keys.first['expid'])
    assert_equal('re-apply', h.values.first['action'])
    assert_equal([ 'hector', {}, [] ], h.values.first['tree'])
  end

  #
  # concurrence testing

  def launch_sam_sam_concurrence

    # TODO
  end

##

  def _test_mutation_of_concurrence

    #
    # prepare workflow execution to mutate

    @dashboard.register do
      sam Ruote::StorageParticipant
      nick Ruote::NoOpParticipant
    end

    pdef0 = Ruote.define do
      concurrence do
        nick
        sam
      end
    end

    wfid = @dashboard.launch(pdef0)
    2.times { @dashboard.wait_for('dispatched') }

    #
    # compute mutations

    # always a re-apply

    pdef1 = Ruote.define do
      concurrence do
        nick
        nick
      end
    end

    mutation = @dashboard.compute_mutation(wfid, pdef1)
    h = mutation.to_h

    pprint(pdef0, pdef1, h)
    #assert_equal(1, h.size)
    #assert_equal("0_0", h.keys.first['expid'])
    #assert_equal("", h.values.first['action'])
    #assert_equal("", h.values.first['tree'])

    # always a re-apply

    pdef1 = Ruote.define do
      concurrence do
        nick
        sam
      end
    end

    mutation = @dashboard.compute_mutation(wfid, pdef1)
    h = mutation.to_h

    pprint(pdef0, pdef1, h)
  end

  def test_mutation_in_concurrence

    #flunk
  end
end

