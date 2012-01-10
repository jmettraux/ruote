
#
# testing ruote
#
# Mon Aug  3 19:19:58 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/util/lookup'


class LookupTest < Test::Unit::TestCase

  def test_lookup

    assert_equal(%w[ A B C ], Ruote.lookup({ 'h' => %w[ A B C ] }, 'h'))
    assert_equal('B', Ruote.lookup({ 'h' => %w[ A B C ] }, 'h.1'))
  end

  def test_hash_lookup_and_number_keys

    assert_equal('B', Ruote.lookup({ '1' => %w[ A B C ] }, '1.1'))
    assert_equal('B', Ruote.lookup({ 1 => %w[ A B C ] }, '1.1'))
  end

  def test_lookup_dot

    h = { 'a' => 'b' }

    assert_equal h, Ruote.lookup(h, '.')
  end

  def test_container_lookup

    assert_equal(
      %w[ A B C ],
      Ruote.lookup({ 'h' => { 'hh' => %w[ A B C ]} }, 'h.hh', false))
    assert_equal(
      [ 'hh', { 'hh' => %w[ A B C ] } ],
      Ruote.lookup({ 'h' => { 'hh' => %w[ A B C ]} }, 'h.hh', true))
  end

  def test_deep_container_lookup

    h = { 'foo' => { 'bar' => { 'baz' => { 'fruit' => 'pineapple' } } } }

    assert_equal(
      "pineapple",
      Ruote.lookup(h, 'foo.bar.baz.fruit', false))
    assert_equal(
      [ 'fruit', { 'fruit' => 'pineapple' } ],
      Ruote.lookup(h, 'foo.bar.baz.fruit', true))
  end

  def test_missing_container_lookup

    assert_equal(
      [ 'nada', nil ],
      Ruote.lookup({ 'h' => { 'hh' => %w[ A B C ]} }, 'nada.nada', true))
  end

  def test_has_key

    h = { 'h' => %w[ a b c ] }

    assert_equal(true, Ruote.has_key?(h, 'h'))
    assert_equal(true, Ruote.has_key?(h, 'h.1'))

    h = { 'foo' => { 'bar' => { 'baz' => { 'fruit' => 'pineapple' } } } }

    assert_equal(true, Ruote.has_key?(h, 'foo.bar.baz.fruit'))
    assert_equal(true, Ruote.has_key?(h, 'foo.bar'))

    assert_equal(false, Ruote.has_key?(h, 'bar'))
  end

  def test_set

    h = { 'customer' => { 'name' => 'alpha' } }
    Ruote.set(h, 'customer.name', 'bravo')

    assert_equal({"customer"=>{"name"=>"bravo"}}, h)
  end

  # courtesy of Nando Sola
  #
  def test_deep_set

    h = { 'foo' => { 'bar' => { 'baz' => { 'fruit' => 'pineapple' } } } }

    Ruote.set(h, 'foo.bar.baz.fruit', 'orange')

    assert_equal(
      { "foo" => { "bar" => { "baz" => { "fruit" => "orange" } } } },
      h)
  end

  def test_set_missing

    h = {}
    Ruote.set(h, 'customer.name', 'bravo')

    assert_equal({ 'customer.name' => 'bravo' }, h)
  end

  def test_set_integer_corner_case

    h = {}
    Ruote.set(h, '0_0_1', 'charly')

    assert_equal({ '0_0_1' => 'charly' }, h)
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

