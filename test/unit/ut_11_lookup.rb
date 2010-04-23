
#
# testing ruote
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

  def test_set

    h = { 'customer' => { 'name' => 'alpha' } }
    Ruote.set(h, 'customer.name', 'bravo')

    assert_equal({"customer"=>{"name"=>"bravo"}}, h)
  end

  def test_set_missing

    h = {}
    Ruote.set(h, 'customer.name', 'bravo')

    assert_equal({"customer.name"=>"bravo"}, h)
  end

  def test_hash_unset

    h = { 'customer' => { 'name' => 'alpha', 'rank' => '1st' } }
    r = Ruote.unset(h, 'customer.rank')

    assert_equal('1st', r)
    assert_equal({ 'customer' => { 'name' => 'alpha' } }, h)
  end

  def test_array_unset

    h = { 'customers' => %w[ alpha bravo charly ] }
    r = Ruote.unset(h, 'customers.1')

    assert_equal('bravo', r)
    assert_equal({ 'customers' => %w[ alpha charly ] }, h)
  end

  def test_array_unset_fail

    h = { 'customers' => %w[ alpha bravo charly ] }
    r = Ruote.unset(h, 'customers.x')

    assert_equal(nil, r)
    assert_equal({ 'customers' => %w[ alpha bravo charly ] }, h)
  end

  def test_unset_fail

    h = { 'customer' => { 'name' => 'alpha', 'rank' => '1st' } }
    r = Ruote.unset(h, 'customer.rank.0')

    assert_equal(nil, r)
    assert_equal({ 'customer' => { 'name' => 'alpha', 'rank' => '1st' } }, h)
  end
end

