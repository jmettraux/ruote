
#
# Testing Ruote (OpenWFEru)
#
# Fri Sep 11 16:09:32 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


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

    assert_trace pdef, %w[ a b c d ]
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

    assert_trace(
      pdef,
      "<:a\n<:b\n>:0\n>:1\n>:0\n>:1\n<:c\n<:c\n>:0\n>:1\n>:0\n>:1")
  end
end

