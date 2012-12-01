
#
# testing ruote
#
# Tue Jul 31 10:53:11 JST 2012
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/util/deep'


class DeepTest < Test::Unit::TestCase

  #--
  # deep_delete
  #++

  def test_deep_delete

    h = { 'a' => 0, 'b' => 1, 'c' => { 'a' => 2, 'b' => { 'a' => 3 } } }

    Ruote.deep_delete(h, 'a')

    assert_equal({ 'b' => 1, 'c' => { 'b' => {} } }, h)
  end

  #--
  # deep_mutate
  #++

  def test_deep_mutate

    h = {
      'a' => 0,
      'b' => 1,
      'c' => { 'a' => 2, 'b' => { 'a' => 3 } },
      'd' => [ { 'a' => 0 }, { 'b' => 4 } ]
    }

    Ruote.deep_mutate(h, 'a') do |coll, k, v|
      coll['a'] = 10
    end

    assert_equal(
      { 'a' => 10,
        'b' => 1,
        'c' => { 'a' => 10, 'b' => { 'a' => 10 } },
        'd' => [ { 'a' => 10 }, { 'b' => 4 } ] },
      h)
  end

  def test_deep_mutate_many

    h = {
      'a' => 0,
      'b' => 1,
      'c' => { 'a' => 2, 'b' => { 'a' => 3 } },
      'd' => [ { 'a' => 0 }, { 'b' => 4 } ]
    }

    Ruote.deep_mutate(h, [ 'a', 'b' ]) do |coll, k, v|
      coll[k] = k * 3
    end

    assert_equal(
      { 'a' => 'aaa',
        'b' => 'bbb',
        'c' => { 'a' => 'aaa', 'b' => 'bbb' },
        'd' => [ { 'a' => 'aaa' }, { 'b' => 'bbb' } ] },
      h)
  end

  def test_deep_mutate_with_parent

    h = { 'a' => { 'b' => { 'c' => 0 } } }

    container = nil

    Ruote.deep_mutate(h, 'c') do |parent_coll, coll, k, v|
      container = parent_coll
    end

    assert_equal({ 'b' => { 'c' => 0 } }, container)
  end

  def test_deep_mutate_with_regexes

    a = [
      { 'user.toto' => :x, 'stuff.toto' => :y },
      { 'user.toto' => :x, 'stuff.toto' => :y }
    ]

    Ruote.deep_mutate(a, /^user\./) do |coll, k, v|
      coll[k] = v.to_s
    end

    assert_equal(
      [ { 'user.toto' => 'x', 'stuff.toto' => :y },
        { 'user.toto' => 'x', 'stuff.toto' => :y } ],
      a)
  end

  def test_deep_mutate_with_key_addition

    h = { 'a' => 0 }

    Ruote.deep_mutate(h, 'a') do |coll, k, v|
      coll.delete(k)
      coll['b'] = 10
    end

    assert_equal(
      { 'b' => 10 },
      h)
  end

  def test_deep_mutate_force_string

    h = { :a => 1, :b => { :a => 2 } }

    Ruote.deep_mutate(h, 'a') do |coll, k, v|
      coll[k] = v * 2
    end

    assert_equal(
      { 'a' => 2, 'b' => { 'a' => 4 } },
      h)
  end

  def test_deep_mutate_key_mutation

    h = { 'a' => { 'a' => 'b' } }

    Ruote.deep_mutate(h, 'a') do |coll, k, v|
      coll.delete('a')
      coll['A'] = v
    end

    assert_equal(
      { 'A' => { 'A' => 'b' } },
      h)
  end
end

