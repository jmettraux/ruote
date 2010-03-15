
#
# testing ruote
#
# Fri Dec 18 19:19:07 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'functional', 'base')


class BmSeqThousandTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_sequence

    n = 100

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        iterator :on => (1..n).to_a do
          echo 'a'
        end
      end
    end

    noisy

    assert_trace [ 'a' ] * n, pdef
  end
end

