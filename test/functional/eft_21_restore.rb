
#
# testing ruote
#
# Tue Aug  4 08:53:33 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftRestoreTest < Test::Unit::TestCase
  include FunctionalBase

  def test_save_to_variable

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        set :field => 'nada', :value => 'surf'
        save :to_variable => 'v'
        unset :field => 'nada'
        echo '-${f:nada}-'
        restore :from_variable => 'v'
        echo '-${f:nada}-'
      end
    end

    #noisy

    assert_trace %w[ -- -surf- ], pdef
  end

  def test_set_fields

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        set_fields :val => { 'a' => 'A', 'b' => 'B' }
        echo '-${f:a}-'
      end
    end

    #noisy

    assert_trace '-A-', pdef
  end

  def test_set_fields_deep

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        set :f => 'h', :val => {}
        set_fields :val => { 'a' => 'A', 'b' => 'B' }, :to => 'h.hh'
        echo '-${f:h.hh.b}-'
      end
    end

    #noisy

    assert_trace '-B-', pdef
  end
end

