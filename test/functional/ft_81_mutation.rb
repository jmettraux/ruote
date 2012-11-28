
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
    @dash.noisy = ENV['NOISY'] == 'true'

    @dash.register do
      sam Ruote::StorageParticipant
      nick Ruote::NoOpParticipant
    end
  end

  def teardown

    @dash.shutdown
  end

  def pprint(t0, t1, mutation)

    puts
    puts '>' + '-' * 79
    p t0
    p t1
    puts mutation
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
    a = mutation.to_a

    #pprint(@pdef, pdef1, mutation)
    assert_equal(0, a.size)
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
    a = mutation.to_a

    #pprint(@pdef, pdef1, mutation)
    assert_equal(1, a.size)
    assert_equal(0, Ruote.extract_child_id(a.first['fei']))
    assert_equal(:update, a.first['action'])
    assert_equal(pdef1, a.first['tree'])
  end

  def test_sequence_change_pre_child

    launch_nick_nick_sam_sequence

    pdef1 = Ruote.define do
      nick
      sam
      sam
    end

    mutation = @dash.compute_mutation(@wfid, pdef1)
    a = mutation.to_a

    #pprint(@pdef, pdef1, mutation)
    assert_equal(1, a.size)
    assert_equal(0, Ruote.extract_child_id(a.first['fei']))
    assert_equal(:re_apply, a.first['action'])
    assert_equal(pdef1, a.first['tree'])
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
    a = mutation.to_a

    #pprint(pdef0, pdef1, mutation)
    assert_equal(3, a.size)

    assert_equal('0', a[0]['fei'].expid)
    assert_equal(:update, a[0]['action'])
    assert_equal('define', a[0]['tree'].first)

    assert_equal('0_1', a[1]['fei'].expid)
    assert_equal(:update, a[1]['action'])
    assert_equal('sequence', a[1]['tree'].first)

    assert_equal('0_1_1', a[2]['fei'].expid)
    assert_equal(:re_apply, a[2]['action'])
    assert_equal('hector', a[2]['tree'].first)
  end

  def test_mutation_apply

    print_header

    pdef0 = Ruote.define do
      sequence do
        nick
        error "nada"
        sam
      end
    end

    wfid = @dash.launch(pdef0)
    @dash.wait_for('error_intercepted')

    pdef1 = Ruote.define do
      sequence do
        nick
        nick
      end
    end

    mutation = @dash.compute_mutation(wfid, pdef1)
    #puts mutation

    mutation.apply

    @dash.wait_for('terminated')

    # the last sam is gone... He didn't get invoked...
  end

  def test_mutation_apply_force_update

    print_header

    pdef0 = Ruote.define do
      sequence do
        nick
        error "nada"
        sam
      end
    end

    wfid = @dash.launch(pdef0)
    @dash.wait_for('error_intercepted')

    pdef1 = Ruote.define do
      sequence do
        nick
        nick
      end
    end

    mutation = @dash.compute_mutation(wfid, pdef1)

    mutation.apply(:force_update)

    ps = @dash.ps(wfid)

    assert_equal(
      [ [ 'define', {}, [
          [ 'sequence', {}, [ ['nick', {}, [] ], ['nick', {}, [] ] ] ] ] ],
        [  'sequence', {}, [ ['nick', {}, [] ], [ 'nick', {}, [] ] ] ],
        [  'nick', {}, [] ] ],
      ps.expressions.collect { |e| e.tree })
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
    a = mutation.to_a

    #pprint(@pdef, pdef1, mutation)
    assert_equal(2, a.size)

    assert_equal('0', a[0]['fei'].expid)
    assert_equal(:update, a[0]['action'])
    assert_equal(pdef1, a[0]['tree'])

    assert_equal('0_0', a[1]['fei'].expid)
    assert_equal(:re_apply, a[1]['action'])
    assert_equal(pdef1[2][0], a[1]['tree'])
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
    a = mutation.to_a

    #pprint(@pdef, pdef1, mutation)
    assert_equal(3, a.size)

    assert_equal('0', a[0]['fei'].expid)
    assert_equal(:update, a[0]['action'])
    assert_equal('define', a[0]['tree'][0])

    assert_equal('0_0', a[1]['fei'].expid)
    assert_equal(:update, a[1]['action'])
    assert_equal('concurrence', a[1]['tree'][0])

    assert_equal('0_0_1', a[2]['fei'].expid)
    assert_equal(:re_apply, a[2]['action'])
    assert_equal('nick', a[2]['tree'][0])
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
    a = mutation.to_a

    #pprint(@pdef, pdef1, mutation)
    assert_equal(2, a.size)

    assert_equal('0', a[0]['fei'].expid)
    assert_equal(:update, a[0]['action'])
    assert_equal('define', a[0]['tree'][0])

    assert_equal('0_0', a[1]['fei'].expid)
    assert_equal(:re_apply, a[1]['action'])
    assert_equal('concurrence', a[1]['tree'][0])
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
    a = mutation.to_a

    #pprint(@pdef, pdef1, mutation)
    assert_equal(3, a.size)

    assert_equal('0', a[0]['fei'].expid)
    assert_equal(:update, a[0]['action'])
    assert_equal('define', a[0]['tree'].first)

    assert_equal('0_0', a[1]['fei'].expid)
    assert_equal(:update, a[1]['action'])
    assert_equal('concurrence', a[1]['tree'].first)

    assert_equal('0_0_1', a[2]['fei'].expid)
    assert_equal(:update, a[2]['action'])

    assert_equal(
      [ 'sequence', {}, [
        [ 'nick', {}, [] ],
        [ 'sam', {}, [] ],
        [ 'sam', {}, [] ] ] ],
      a[2]['tree'])
  end
end

