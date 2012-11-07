
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

    print_header

    @pdef = Ruote.define do
      concurrence do
        sam
        sam
      end
    end

    @wfid = @dash.launch(@pdef)
    2.times { @dash.wait_for('dispatched') }
  end

  def test_concurrence_add_branch

    launch_sam_sam_concurrence

    pdef1 = Ruote.define do
      concurrence do
        sam
        sam
        nick
      end
    end

    mutation = @dash.compute_mutation(@wfid, pdef1)
    h = mutation.to_h

    #pprint(@pdef, pdef1, h)
    assert_equal(1, h.size)
    assert_equal('0_0', h.keys.first['expid'])
    assert_equal('re-apply', h.values.first['action'])
    assert_equal(pdef1[2][0], h.values.first['tree'])
  end

  def test_concurrence

    launch_sam_sam_concurrence

    pdef1 = Ruote.define do
      concurrence do
        sam
        nick
      end
    end

    mutation = @dash.compute_mutation(@wfid, pdef1)
    h = mutation.to_h

    #pprint(@pdef, pdef1, h)
    assert_equal(1, h.size)
    assert_equal('0_0_1', h.keys[0]['expid'])
    assert_equal('re-apply', h.values[0]['action'])
    assert_equal('nick', h.values[0]['tree'][0])
  end

  def launch_sam_nick_concurrence

    print_header

    @pdef = Ruote.define do
      concurrence do
        sam
        nick
      end
    end

    @wfid = @dash.launch(@pdef)
    2.times { @dash.wait_for('dispatched') }
  end

  def test_concurrence_change_child_that_already_replied

    launch_sam_nick_concurrence

    pdef1 = Ruote.define do
      concurrence do
        sam
        sam
      end
    end

    mutation = @dash.compute_mutation(@wfid, pdef1)
    h = mutation.to_h

    #pprint(@pdef, pdef1, h)
    assert_equal(1, h.size)
    assert_equal('0_0', h.keys[0]['expid'])
    assert_equal('re-apply', h.values[0]['action'])
    assert_equal('concurrence', h.values[0]['tree'][0])
  end

  def launch_deep_concurrence

    print_header

    @pdef = Ruote.define do
      concurrence do
        sam
        sequence do
          nick
          sam
        end
      end
    end

    @wfid = @dash.launch(@pdef)
    2.times { @dash.wait_for('dispatched') }
  end

  def test_deep_inside_of_concurrence

    launch_deep_concurrence

    pdef1 = Ruote.define do
      concurrence do
        sam
        sequence do
          nick
          sam
          sam
        end
      end
    end

    mutation = @dash.compute_mutation(@wfid, pdef1)
    h = mutation.to_h

    #pprint(@pdef, pdef1, h)

    assert_equal(1, h.size)
    assert_equal('0_0_1', h.keys[0]['expid'])
    assert_equal('update', h.values[0]['action'])

    assert_equal(
      [ "sequence", {}, [
        [ "nick", {}, [] ],
        [ "sam", {}, [] ],
        [ "sam", {}, [] ] ] ],
      h.values[0]['tree'])
  end
end

