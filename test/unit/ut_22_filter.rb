
#
# testing ruote
#
# Sun Jan 30 21:08:14 JST 2011
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require_json
require 'rufus/json'
require 'ruote/util/filter'


class UtFilterTest < Test::Unit::TestCase

  #
  # some helpers

  def assert_filter (result, filter, hash)

    assert_equal(result, Ruote.filter(Rufus::Json.dup(filter), hash))
  end

  def assert_valid (filter, hash)

    Ruote.filter(Rufus::Json.dup(filter), hash)
    assert true
  end

  def assert_not_valid (filter, hash)

    assert_raise Ruote::ValidationError do
      Ruote.filter(Rufus::Json.dup(filter), hash)
    end
  end

  #
  # the tests

  def test_remove

    assert_filter(
      {},
      [ { 'field' => 'x', 'remove' => true } ],
      { 'x' => 'y' })

    assert_filter(
      { 'x' => {} },
      [ { 'field' => 'x.y', 'remove' => true } ],
      { 'x' => { 'y' => 'z' } })
  end

  def test_default

    assert_filter(
      { 'x' => 1 },
      [ { 'field' => 'x', 'default' => 1 } ],
      {})

    assert_filter(
      { 'x' => 2 },
      [ { 'field' => 'x', 'default' => 1 } ],
      { 'x' => 2 })

    assert_filter(
      { 'x' => { 'y' => 1 } },
      [ { 'field' => 'x.y', 'default' => 1 } ],
      { 'x' => {} })

    assert_filter(
      { 'x' => { 'y' => 2 } },
      [ { 'field' => 'x.y', 'default' => 1 } ],
      { 'x' => { 'y' => 2 } })

    assert_filter(
      { 'x' => { 'y' => 1 } },
      [ { 'field' => 'x', 'default' => {} },
        { 'field' => 'x.y', 'default' => 1 } ],
      {})
  end

  def test_type

    assert_valid(
      [ { 'field' => 'x', 'type' => 'string' } ], { 'x' => 'deux' })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'number' } ], { 'x' => 1 })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'number' } ], { 'x' => 1.0 })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'object' } ], { 'x' => {} })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'hash' } ], { 'x' => {} })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'array' } ], { 'x' => [] })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'boolean' } ], { 'x' => true })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'boolean' } ], { 'x' => false })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'bool' } ], { 'x' => true })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'bool' } ], { 'x' => false })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'null' } ], { 'x' => nil })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'null' } ], {})
    assert_valid(
      [ { 'field' => 'x', 'type' => 'nil' } ], {})

    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'string' } ], { 'x' => 2 })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'number' } ], { 'x' => 'one' })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'number' } ], { 'x' => '1.0' })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'object' } ], { 'x' => [] })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'hash' } ], { 'x' => [] })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'array' } ], { 'x' => {} })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'boolean' } ], { 'x' => 'true' })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'boolean' } ], { 'x' => 'false' })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'bool' } ], { 'x' => 'true' })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'bool' } ], { 'x' => 'true' })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'null' } ], { 'x' => false })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'null' } ], { 'x' => 1 })
  end

  def test_type_deep

    assert_valid(
      [ { 'field' => 'x.y', 'type' => 'string' } ], { 'x' => { 'y' => 'z' } })

    assert_not_valid(
      [ { 'field' => 'x.y', 'type' => 'string' } ], { 'x' => { 'y' => 1 } })
  end

  def test_type_union

    assert_valid(
      [ { 'field' => 'x', 'type' => 'string,number' } ], { 'x' => 'a' })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'string,number' } ], { 'x' => 1 })
    assert_valid(
      [ { 'field' => 'x', 'type' => [ 'string', 'number' ] } ], { 'x' => 'a' })
    assert_valid(
      [ { 'field' => 'x', 'type' => [ 'string', 'number' ] } ], { 'x' => 1 })
  end

  def test_type_and_null

    assert_valid(
      [ { 'field' => 'x', 'type' => 'string,null' } ], {})
    assert_valid(
      [ { 'field' => 'x', 'type' => 'string,null' } ], { 'x' => nil })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'string,null' } ], { 'x' => 'x' })
  end

  def test_or

    assert_filter(
      { 'x' => 'y' },
      [ { 'field' => 'x', 'type' => 'string', 'or' => 'z' } ],
      { 'x' => 'y' })
    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => 'x', 'type' => 'string', 'or' => 'z' } ],
      { 'x' => 2 })
  end

  def test_nil_or

    assert_filter(
      { 'x' => 'y' },
      [ { 'field' => 'x', 'or' => 'z' } ],
      { 'x' => 'y' })
    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => 'x', 'or' => 'z' } ],
      {})
    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => 'x', 'or' => 'z' } ],
      { 'x' => nil })
  end

  def test_and

    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => 'x', 'type' => 'string', 'and' => 'z' } ],
      { 'x' => 'y' })
    assert_filter(
      { 'x' => 1 },
      [ { 'field' => 'x', 'type' => 'string', 'and' => 'z' } ],
      { 'x' => 1 })
  end

  def test_set

    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => 'x', 'set' => 'z' } ],
      { 'x' => 'y' })
    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => 'x', 'set' => 'z' } ],
      {})
  end

  def test_match

    assert_valid(
      [ { 'field' => 'x', 'match' => 'to' } ],
      { 'x' => 'toto' })
    assert_valid(
      [ { 'field' => 'x', 'match' => '1' } ],
      { 'x' => 1.0 })

    assert_not_valid(
      [ { 'field' => 'x', 'match' => 'to' } ],
      { 'x' => 'tutu' })
    assert_not_valid(
      [ { 'field' => 'x', 'match' => '1' } ],
      { 'x' => 2.0 })
  end

  def test_smatch

    assert_valid(
      [ { 'field' => 'x', 'smatch' => 'to' } ],
      { 'x' => 'toto' })
    assert_not_valid(
      [ { 'field' => 'x', 'smatch' => '1' } ],
      { 'x' => 1.0 })

    assert_not_valid(
      [ { 'field' => 'x', 'smatch' => 'to' } ],
      { 'x' => 'tutu' })
    assert_not_valid(
      [ { 'field' => 'x', 'smatch' => '1' } ],
      { 'x' => 2.0 })
  end

  def test_copy

    assert_filter(
      { 'x' => 'y', 'z' => 'y' },
      [ { 'field' => 'x', 'copy_to' => 'z' } ],
      { 'x' => 'y' })
    assert_filter(
      { 'x' => 'y', 'z' => 'y' },
      [ { 'field' => 'z', 'copy_from' => 'x' } ],
      { 'x' => 'y' })
  end

  def test_move

    assert_filter(
      { 'z' => 'y' },
      [ { 'field' => 'x', 'move_to' => 'z' } ],
      { 'x' => 'y' })
    assert_filter(
      { 'z' => 'y' },
      [ { 'field' => 'z', 'move_from' => 'x' } ],
      { 'x' => 'y' })
  end

  def test_size

    assert_valid(
      [ { 'field' => 'x', 'size' => 4 } ],
      { 'x' => 'toto' })
    assert_valid(
      [ { 'field' => 'x', 'size' => '4' } ],
      { 'x' => 'toto' })
    assert_valid(
      [ { 'field' => 'x', 'size' => 4 } ],
      { 'x' => %w[ a b c d ] })
    assert_valid(
      [ { 'field' => 'x', 'size' => 2 } ],
      { 'x' => { 'a' => 'b', 'c' => 'd' } })

    assert_not_valid(
      [ { 'field' => 'x', 'size' => 2 } ],
      {})
    assert_not_valid(
      [ { 'field' => 'x', 'size' => 2 } ],
      { 'x' => 3 })
  end

  def test_size_range

    assert_valid(
      [ { 'field' => 'x', 'size' => [ 2, 3 ] } ],
      { 'x' => %w[ a b ] })
    assert_valid(
      [ { 'field' => 'x', 'size' => [ 2, 3 ] } ],
      { 'x' => %w[ a b c ] })

    assert_not_valid(
      [ { 'field' => 'x', 'size' => [ 2, 3 ] } ],
      { 'x' => %w[ a ] })
    assert_not_valid(
      [ { 'field' => 'x', 'size' => [ 2, 3 ] } ],
      { 'x' => %w[ a b c d ] })
  end

  def test_size_open_range

    assert_valid(
      [ { 'field' => 'x', 'size' => [ 2, nil ] } ],
      { 'x' => %w[ a b ] })
    assert_valid(
      [ { 'field' => 'x', 'size' => ",3" } ],
      { 'x' => %w[ a b c ] })

    assert_not_valid(
      [ { 'field' => 'x', 'size' => "2," } ],
      { 'x' => %w[ a ] })
    assert_not_valid(
      [ { 'field' => 'x', 'size' => [ nil, 3 ] } ],
      { 'x' => %w[ a b c d ] })
  end

  def test_empty

    assert_valid(
      [ { 'field' => 'x', 'empty' => true } ],
      { 'x' => %w[] })
    assert_valid(
      [ { 'field' => 'x', 'empty' => true } ],
      { 'x' => {} })
    assert_valid(
      [ { 'field' => 'x', 'empty' => true } ],
      { 'x' => '' })

    assert_not_valid(
      [ { 'field' => 'x', 'empty' => true } ],
      { 'x' => 'deux' })
    assert_not_valid(
      [ { 'field' => 'x', 'empty' => true } ],
      { 'x' => %w[ a b ] })
    assert_not_valid(
      [ { 'field' => 'x', 'empty' => true } ],
      { 'x' => { 'a' =>  'b' } })
  end

  def test_in

    assert_valid(
      [ { 'field' => 'x', 'in' => %w[ alpha bravo ] } ],
      { 'x' => 'alpha' })
    assert_valid(
      [ { 'field' => 'x', 'in' => "alpha, bravo" } ],
      { 'x' => 'alpha' })

    assert_not_valid(
      [ { 'field' => 'x', 'in' => %w[ alpha bravo ] } ],
      { 'x' => 'charly' })
    assert_not_valid(
      [ { 'field' => 'x', 'in' => "alpha, bravo" } ],
      { 'x' => 'charly' })
  end
end

