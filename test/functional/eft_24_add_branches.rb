#
# testing ruote
#
# Fri Sep 11 16:09:32 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftAddBranchesTest < Test::Unit::TestCase
  include FunctionalBase


  def test_add_branches

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on => 'a, b' do
        sequence do
          echo '${v:i}'
          add_branches 'c, d', :if => '${v:ii} == 0'
        end
      end
    end

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    assert_equal %w[ a b c d ], @tracer.to_a.sort
  end

  def test_add_branches_times

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :times => 3 do
        sequence do
          echo '${v:i}'
          add_branches 2, :if => '${v:i} == 1'
        end
      end
    end

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    assert_equal %w[ 0 1 2 3 4 ], @tracer.to_a.sort
  end

  def test_add_branches_times_and_whatever

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :times => 3 do
        sequence do
          echo '${v:i}'
          add_branches 'a, b', :if => '${v:i} == 1'
        end
      end
    end

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    assert_equal %w[ 0 1 2 a b ], @tracer.to_a.sort
  end

  def test_add_branches_with_tag

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on => 'a, b', :to_v => 'x', :tag => 'here' do
        sequence do
          echo '<:${v:x}'
          concurrent_iterator :on => '0, 1' do
            sequence do
              echo '>:${v:i}'
              add_branch 'c', :ref => 'here', :if => '${v:x} == a'
            end
          end
        end
      end
    end

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    assert_equal(
      %w[ <:a <:b <:c <:c >:0 >:0 >:0 >:0 >:1 >:1 >:1 >:1 ],
      @tracer.to_a.sort)
  end
end

