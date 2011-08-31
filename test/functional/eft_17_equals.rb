
#
# testing ruote
#
# Thu Jul  9 13:31:59 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftEqualsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_false

    pdef = Ruote.process_definition :name => 'test' do
      sequence do

        equals :field_value => 'missing', :other_value => 'nada'
        echo '${f:__result__}'
        equals :variable_value => 'missing', :other_value => 'nada'
        echo '${f:__result__}'

        equals :value => 'missing', :other_value => 'nada'
        echo '${f:__result__}'
        equals :val => 'missing', :other_val => 'nada'
        echo '${f:__result__}'
      end
    end

    #noisy

    assert_trace(%w[ false ] * 4, pdef)
  end

  def test_true

    pdef = Ruote.process_definition :name => 'test' do
      sequence do

        equals :value => 'nada', :other_value => 'nada'
        echo '${f:__result__}'

        set 'v:nada' => 'nada'
        equals :variable_value => 'nada', :other_value => 'nada'
        echo '${f:__result__}'
      end
    end

    #noisy

    assert_trace(%w[ true ] * 2, pdef)
  end
end

