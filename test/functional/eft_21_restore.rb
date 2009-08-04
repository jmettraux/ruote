
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Aug  4 08:53:33 JST 2009
#

require File.dirname(__FILE__) + '/base'

#require 'ruote/part/hash_participant'


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

    assert_trace pdef, %w[ -- -surf- ]
  end

  def test_set_fields

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        set_fields :val => { 'a' => 'A', 'b' => 'B' }
        echo '-${f:a}-'
      end
    end

    #noisy

    assert_trace pdef, '-A-'
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

    assert_trace pdef, '-B-'
  end
end

