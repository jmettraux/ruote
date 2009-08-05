
#
# Testing Ruote
#
# Mon Aug  3 19:19:58 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/util/lookup'


class LookupTest < Test::Unit::TestCase

  def test_lookup

    assert_equal(%w[ A B C ], Ruote.lookup({ 'h' => %w[ A B C ] }, 'h'))
    assert_equal('B', Ruote.lookup({ 'h' => %w[ A B C ] }, 'h.1'))
  end

  def test_container_lookup

    assert_equal(
      [ 'hh', { 'hh' => %w[ A B C ] } ],
      Ruote.lookup({ 'h' => { 'hh' => %w[ A B C ]} }, 'h.hh', true))
  end

  def test_missing_container_lookup

    assert_equal(
      [ 'nada', nil ],
      Ruote.lookup({ 'h' => { 'hh' => %w[ A B C ]} }, 'nada.nada', true))
  end
end

