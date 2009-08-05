
#
# Testing Ruote (OpenWFEru)
#
# Thu Jul  9 13:31:59 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class EftEqualsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_false

    pdef = Ruote.process_definition :name => 'test' do
      sequence do

        equals :field_value => 'missing', :other_value => 'nada'
        echo '${f:__result__}'

        equals :value => 'missing', :other_value => 'nada'
        echo '${f:__result__}'
        equals :val => 'missing', :other_val => 'nada'
        echo '${f:__result__}'
      end
    end

    #noisy

    assert_trace(pdef, %w[ false false false ])
  end

  def test_true

    pdef = Ruote.process_definition :name => 'test' do
      sequence do

        equals :value => 'nada', :other_value => 'nada'
        echo '${f:__result__}'
      end
    end

    #noisy

    assert_trace(pdef, %w[ true ])
  end
end

