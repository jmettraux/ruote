
#
# testing ruote
#
# Sun Jan 30 21:08:14 JST 2011
#

require File.expand_path('../../test_helper', __FILE__)

require_json
require 'rufus/json'
require 'ruote/util/filter'


class UtFilterTest < Test::Unit::TestCase

  def test_missing_field

    assert_raise ArgumentError do
      Ruote.filter([ { 'type' => 'string' } ], {})
    end
  end

  def test_not_a_filter

    assert_raise ArgumentError do
      Ruote.filter('nada', {})
    end
  end

  #
  # transformations

  def assert_filter(result, filter, hash, double_tilde=nil)

    assert_equal(
      result,
      Ruote.filter(
        Rufus::Json.dup(filter), hash, :double_tilde => double_tilde))
  end

  def test_remove

    assert_filter(
      {},
      [ { 'field' => 'x', 'remove' => true } ],
      { 'x' => 'y' })
    assert_filter(
      {},
      [ { 'field' => '/.+/', 'remove' => true } ],
      { 'x' => 'y', 'z' => 'a' })

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
      { 'x' => 1 },
      [ { 'field' => 'x', 'default' => 1 } ],
      { 'x' => nil })

    assert_filter(
      {},
      [ { 'field' => '/.+/', 'default' => 1 } ],
      {})
    assert_filter(
      { 'x' => 1 },
      [ { 'field' => '/.+/', 'default' => 1 } ],
      { 'x' => nil })

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

  def test_or

    assert_filter(
      { 'x' => 'y' },
      [ { 'field' => 'x', 'type' => 'string', 'or' => 'z' } ],
      { 'x' => 'y' })
    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => 'x', 'type' => 'string', 'or' => 'z' } ],
      { 'x' => 2 })

    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => '/.+/', 'type' => 'string', 'or' => 'z' } ],
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

    assert_filter(
      {},
      [ { 'field' => '/.+/', 'or' => 'z' } ],
      {})
    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => '/.+/', 'or' => 'z' } ],
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

    assert_filter(
      { 'x' => 1, 'z' => 1 },
      [ { 'field' => '/.+/', 'type' => 'string', 'and' => 1 } ],
      { 'x' => 'y', 'z' => 'a' })
    assert_filter(
      { 'x' => 1, 'z' => 2 },
      [ { 'field' => '/.+/', 'type' => 'string', 'and' => 1 } ],
      { 'x' => 'y', 'z' => 2 })
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

    assert_filter(
      { 'x' => 'z' },
      [ { 'field' => '/.+/', 'set' => 'z' } ],
      { 'x' => 'y' })
    assert_filter(
      {},
      [ { 'field' => '/.+/', 'set' => 'z' } ],
      {})
  end

  def test_set_multiple_fields

    assert_filter(
      { 'x' => 'A', 'y' => 'A', 'z' => 'A' },
      [ { 'field' => 'x,y,z', 'set' => 'A' } ],
      {})
    assert_filter(
      { 'x' => 'A', 'y' => 'A', 'z' => 'A' },
      [ { 'fields' => %w[ x y z ], 'set' => 'A' } ],
      {})
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

  def test_copy_and_regex

    assert_filter(
      { 'a' => %w[ x y ], 'b0' => 'x', 'b1' => 'y' },
      [ { 'field' => '/a\.(.+)/', 'copy_to' => 'b\1' } ],
      { 'a' => %w[ x y ]})
    assert_filter(
      { 'a' => %w[ x y ], 'b0' => 'x', 'b1' => 'y' },
      [ { 'field' => '/a!(.+)/', 'copy_to' => 'b\1' } ],
      { 'a' => %w[ x y ]})

    assert_filter(
      { 'a' => 7, 'c' => 7, 'source' => [ 7 ] },
      [ { 'field' => '/^.$/', 'copy_from' => 'source.0' } ],
      { 'a' => 'b', 'c' => 'd', 'source' => [ 7 ] })
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

  def test_move_and_regex

    assert_filter(
      { 'Z' => 'a' },
      [ { 'field' => '/.+/', 'move_to' => 'Z' } ],
      { 'x' => 'y', 'z' => 'a' })
    assert_filter(
      { 'prefix_x' => 'y', 'prefix_z' => 'a' },
      [ { 'field' => '/(.+)/', 'move_to' => 'prefix_\1' } ],
      { 'x' => 'y', 'z' => 'a' })

    assert_filter(
      { 'h0' => {}, 'h1' => { 'a' => 'b', 'c' => 'd' } },
      [ { 'field' => '/^h0!(.+)/', 'move_to' => 'h1.\1' } ],
      { 'h0' => { 'a' => 'b', 'c' => 'd' }, 'h1' => {} })
  end

  def test_merge_from

    assert_filter(
      { 'x' => { 'a' => 'A', 'b' => 2, 'c' => 'C' }, 'y' => { 'a' => 'A', 'c' => 'C' } },
      [ { 'field' => 'x', 'merge_from' => 'y' } ],
      { 'x' => { 'a' => 1, 'b' => 2 }, 'y' => { 'a' => 'A', 'c' => 'C' } })
  end

  def test_merge_to

    assert_filter(
      { 'x' => { 'a' => 1, 'b' => 2 }, 'y' => { 'a' => 1, 'b' => 2, 'c' => 'C' } },
      [ { 'field' => 'x', 'merge_to' => 'y' } ],
      { 'x' => { 'a' => 1, 'b' => 2 }, 'y' => { 'a' => 'A', 'c' => 'C' } })

    assert_filter(
      { 'x' => { 'a' => 1, 'b' => 2 }, 'y' => 2 },
      [ { 'field' => 'x', 'mg_to' => 'y' } ],
      { 'x' => { 'a' => 1, 'b' => 2 }, 'y' => 2 })
  end

  def test_merge_to__non_hash

    assert_filter(
      { 'x' => { 'a' => 1, 'y' => 2 }, 'y' => 2 },
      [ { 'field' => 'y', 'mg_to' => 'x' } ],
      { 'x' => { 'a' => 1 }, 'y' => 2 })

    assert_filter(
      { 'x' => { 'a' => 1 }, 'y' => 2 },
      [ { 'field' => 'x', 'mg_to' => 'y' } ],
      { 'x' => { 'a' => 1 }, 'y' => 2 })
  end

  def test_merge_to__array # push too

    assert_filter(
      { 'x' => [ 'a', 'b', 2 ], 'y' => 2 },
      [ { 'field' => 'y', 'mg_to' => 'x' } ],
      { 'x' => [ 'a', 'b' ], 'y' => 2 })
    assert_filter(
      { 'x' => [ 'a', 'b', 2 ], 'y' => 2 },
      [ { 'field' => 'y', 'push_to' => 'x' } ],
      { 'x' => [ 'a', 'b' ], 'y' => 2 })
    assert_filter(
      { 'x' => [ 'a', 'b', 2 ], 'y' => 2 },
      [ { 'field' => 'y', 'pu_to' => 'x' } ],
      { 'x' => [ 'a', 'b' ], 'y' => 2 })
  end

  def test_merge_from__non_hash

    assert_filter(
      { 'x' => { 'a' => 1, 'y' => 2 }, 'y' => 2 },
      [ { 'field' => 'x', 'merge_from' => 'y' } ],
      { 'x' => { 'a' => 1 }, 'y' => 2 })
  end

  def test_merge_from__array

    assert_filter(
      { 'x' => [ 'a', 'b', 2 ], 'y' => 2 },
      [ { 'field' => 'x', 'merge_from' => 'y' } ],
      { 'x' => [ 'a', 'b' ], 'y' => 2 })
    assert_filter(
      { 'x' => [ 'a', 'b', 2 ], 'y' => 2 },
      [ { 'field' => 'x', 'push_from' => 'y' } ],
      { 'x' => [ 'a', 'b' ], 'y' => 2 })
    assert_filter(
      { 'x' => [ 'a', 'b', 2 ], 'y' => 2 },
      [ { 'field' => 'x', 'pu_from' => 'y' } ],
      { 'x' => [ 'a', 'b' ], 'y' => 2 })
  end

  def test_merge_dot

    assert_filter(
      { 'x' => { 'a' => 1, 'b' => 2 }, 'a' => 1, 'b' => 2 },
      [ { 'field' => 'x', 'merge_to' => '.' } ],
      { 'x' => { 'a' => 1, 'b' => 2 } })

    assert_filter(
      { 'x' => { 'a' => 1, 'b' => 2, 'x' => { 'a' => 1, 'b' => 2 } } },
      [ { 'field' => 'x', 'merge_from' => '.' } ],
      { 'x' => { 'a' => 1, 'b' => 2 } })
  end

  def test_migrate

    assert_filter(
      { 'x' => { 'a' => 'A', 'b' => 2, 'c' => 'C' } },
      [ { 'field' => 'x', 'migrate_from' => 'y' } ],
      { 'x' => { 'a' => 1, 'b' => 2 }, 'y' => { 'a' => 'A', 'c' => 'C' } })

    assert_filter(
      { 'y' => { 'a' => 1, 'b' => 2, 'c' => 'C' } },
      [ { 'field' => 'x', 'migrate_to' => 'y' } ],
      { 'x' => { 'a' => 1, 'b' => 2 }, 'y' => { 'a' => 'A', 'c' => 'C' } })

    assert_filter(
      { 'x' => { 'a' => 1, 'b' => 2 }, 'y' => 2 },
      [ { 'field' => 'x', 'migrate_to' => 'y' } ],
      { 'x' => { 'a' => 1, 'b' => 2 }, 'y' => 2 })
  end

  def test_migrate_dot

    assert_filter(
      { 'a' => 1, 'b' => 2 },
      [ { 'field' => 'x', 'mi_to' => '.' } ],
      { 'x' => { 'a' => 1, 'b' => 2 } })

    assert_filter(
      { 'x' => { 'a' => 1, 'b' => 2, 'x' => { 'a' => 1, 'b' => 2 } } },
      [ { 'field' => 'x', 'mi_from' => '.' } ],
      { 'x' => { 'a' => 1, 'b' => 2 } })
  end

  def test_tilde

    assert_filter(
      { 'x' => 'a', 'y' => 'a' },
      [ { 'field' => 'x', 'set' => 'b' },
        { 'field' => 'x', 'copy_from' => '~.x' },
        { 'field' => 'y', 'copy_from' => '~.x' } ],
      { 'x' => 'a' })
  end

  def test_tilde_restoring

    assert_filter(
      { 'private_x' => 'a' },
      [ { 'field' => '/^private_/', 'del' => true },
        { 'field' => '/^~~.private_/', 'merge_to' => '.' } ],
      { 'private_x' => 'a' })
  end

  def test_restore

    assert_filter(
      { 'x' => 'a', 'y' => 'a' },
      [ { 'field' => 'x', 'set' => 'X' },
        { 'field' => 'y', 'set' => 'Y' },
        { 'field' => '/^.$/', 'restore' => true } ],
      { 'x' => 'a', 'y' => 'a' })
  end

  def test_restore_with_a_given_prefix

    assert_filter(
      { 'x' => 'a', 'y' => 'a' },
      [ { 'field' => 'A', 'set' => {} },
        { 'field' => '.', 'merge_to' => 'A' },
        { 'field' => 'x', 'set' => 'X' },
        { 'field' => 'y', 'set' => 'Y' },
        { 'field' => '/^[a-z]$/', 'restore_from' => 'A' },
        { 'field' => 'A', 'delete' => true } ],
      { 'x' => 'a', 'y' => 'a' })
  end

  def test_really_restore

    assert_filter(
      { 'x' => 'a', 'y' => 'a', 'z' => 'good' },
      [ { 'field' => '/./', 'del' => true },
        { 'field' => 'y', 'set' => 'bad' },
        { 'field' => 'z', 'set' => 'good' },
        { 'field' => '/./', 'restore' => true } ],
      { 'x' => 'a', 'y' => 'a' })
  end

  def test_cumulation_or

    assert_filter(
      { 'x' => { 'a' => 2 } },
      [ { 'field' => 'x', 't' => 'hash', 'has' => 'a', 'or' => { 'a' => 2 } } ],
      { 'x' => %w[ a b c ] })
  end

  def test_take

    assert_filter(
      { 'x' => 'a', 'z' => 'b' },
      [ { 'field' => 'x', 'take' => 'true' } ],
      { 'x' => 'a', 'y' => 'a' },
      { 'z' => 'b' }) # ~~
  end

  def test_discard

    assert_filter(
      { 'y' => 'a', 'z' => 'b' },
      [ { 'field' => 'x', 'discard' => 'true' } ],
      { 'x' => 'a', 'y' => 'a' },
      { 'z' => 'b' }) # ~~
  end

  def test_discard_multiple

    assert_filter(
      { 'z' => 'a', '1' => 'b' },
      [ { 'field' => 'x|y', 'discard' => 'true' } ],
      { 'x' => 'a', 'y' => 'a', 'z' => 'a' },
      { '1' => 'b' }) # ~~
  end

  #
  # validations

  def assert_valid(filter, hash)

    begin
      Ruote.filter(Rufus::Json.dup(filter), hash)
      assert true
    rescue Ruote::ValidationError => ve
      puts
      puts
      p ve
      p ve.deviations
      puts
      puts 'hash:'
      p hash
      puts 'filter:'
      filter.each { |l| p l }
      puts
      assert false
    end
  end

  def assert_not_valid(filter, hash, opts={ :deviations => 1 })

    error = nil

    begin
      Ruote.filter(Rufus::Json.dup(filter), hash)
    rescue => error
    end

    p error.deviations if opts[:verbose]

    assert_not_nil(
      error, "ValidationError was not raised")
    assert_equal(
      opts[:deviations], error.deviations.size, "deviation count doesn't match")

    @deviations = error.deviations
  end

  def test_presence

    assert_valid(
      [ { 'field' => 'x' } ], { 'x' => 'deux' })
    assert_not_valid(
      [ { 'field' => 'x' } ], { 'y' => 'trois' })

    assert_valid(
      [ { 'field' => '/x|y/' } ], { 'x' => 'deux' })
    assert_not_valid(
      [ { 'field' => '/x|y/' } ], { 'z' => 'quatre' })
  end

  def test_this_or_that_field

    assert_valid(
      [ { 'field' => 'x|y', 'type' => 'string' } ], { 'x' => 'deux' })
    assert_valid(
      [ { 'field' => 'x|y', 'type' => 'string' } ], { 'y' => 'trois' })


    assert_valid(
      [ { 'field' => 'x|y'} ], { 'x' => 'deux' })

    assert_not_valid(
      [ { 'field' => 'x|y', 'type' => 'string' } ], { 'z' => 'quatre' })
    assert_not_valid(
      [ { 'field' => 'x|y' } ], { 'z' => 'quatre' })
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

    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'string' } ], {})
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

  def test_type_array

    assert_valid(
      [ { 'field' => 'x', 'type' => 'array<string>' } ],
      { 'x' => %w[ a b c ] })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'array<string,number>' } ],
      { 'x' => [ 'a', 1 ] })

    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'array<string>' } ],
      { 'x' => [ 'a', 1 ] })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'array<string,number>' } ],
      { 'x' => [ 'a', true ] })
  end

  def test_type_array_deep

    assert_valid(
      [ { 'field' => 'x', 'type' => 'array<array<string>>' } ],
      { 'x' => [ %w[ a b ], %w[ c d ] ] })

    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'array<array<string>>' } ],
      { 'x' => [ %w[ a b ], [ 2, 3 ] ] })
  end

  def test_type_hash

    assert_valid(
      [ { 'field' => 'x', 'type' => 'hash<string>' } ],
      { 'x' => { 'a' => 'b', 'c' => 'd' } })
    assert_valid(
      [ { 'field' => 'x', 'type' => 'hash<string,number>' } ],
      { 'x' => { 'a' => 'b', 'c' => 0 } })

    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'hash<string>' } ],
      { 'x' => { 'a' => 'b', 'c' => 0 } })
    assert_not_valid(
      [ { 'field' => 'x', 'type' => 'hash<string,number>' } ],
      { 'x' => { 'a' => 'b', 'c' => true } })
  end

  def test_type_and_regex

    assert_valid(
      [ { 'field' => '/./', 'type' => 'string' } ],
      { 'x' => 'y', 'z' => 'a' })

    assert_not_valid(
      [ { 'field' => '/./', 'type' => 'string' } ],
      { 'x' => 'y', 'z' => 1 })

    assert_not_valid(
      [ { 'field' => '/./', 'type' => 'string' } ],
      { 'x' => 1, 'z' => 1 },
      :deviations => 2)
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

  def test_is

    assert_valid(
      [ { 'field' => 'x', 'is' => true } ],
      { 'x' => true })
    assert_valid(
      [ { 'field' => 'x', 'is' => (1..3).to_a } ],
      { 'x' => [ 1, 2, 3 ] })

    assert_not_valid(
      [ { 'field' => 'x', 'is' => false } ],
      { 'x' => true })
    assert_not_valid(
      [ { 'field' => 'x', 'is' => true } ],
      { 'x' => 1 })
    assert_not_valid(
      [ { 'field' => 'x', 'is' => (1..3).to_a } ],
      { 'x' => [ 3, 2, 1 ] })
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
      [ { 'field' => 'x', 'size' => [ 2 ] } ],
      { 'x' => %w[ a b ] })
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
    assert_valid(
      [ { 'field' => 'x', 'empty' => false } ],
      { 'x' => [ 1 ] })

    assert_not_valid(
      [ { 'field' => 'x', 'empty' => true } ],
      { 'x' => 'deux' })
    assert_not_valid(
      [ { 'field' => 'x', 'empty' => true } ],
      { 'x' => %w[ a b ] })
    assert_not_valid(
      [ { 'field' => 'x', 'empty' => true } ],
      { 'x' => { 'a' =>  'b' } })
    assert_not_valid(
      [ { 'field' => 'x', 'empty' => false } ],
      { 'x' => {} })
  end

  def test_string_and_empty

    assert_valid(
      [ { 'field' => 'x', 'empty' => true, 'type' => 'string' } ],
      { 'x' => '' })
    assert_valid(
      [ { 'field' => 'x', 'empty' => false, 'type' => 'string' } ],
      { 'x' => 'yyy' })

    assert_not_valid(
      [ { 'field' => 'x', 'empty' => true, 'type' => 'string' } ],
      { 'x' => {} })
  end

  def test_in

    assert_valid(
      [ { 'field' => 'x', 'in' => %w[ alpha bravo ] } ],
      { 'x' => 'alpha' })
    assert_valid(
      [ { 'field' => 'x', 'in' => "alpha, bravo" } ],
      { 'x' => 'alpha' })
    assert_valid(
      [ { 'field' => 'x', 'in' => [ true ] } ],
      { 'x' => true })

    assert_not_valid(
      [ { 'field' => 'x', 'in' => %w[ alpha bravo ] } ],
      { 'x' => 'charly' })
    assert_not_valid(
      [ { 'field' => 'x', 'in' => "alpha, bravo" } ],
      { 'x' => 'charly' })
    assert_not_valid(
      [ { 'field' => 'x', 'in' => [ false ] } ],
      { 'x' => true })
  end

  def test_has__keys

    assert_valid(
      [ { 'field' => '.', 'has' => 'x' } ],
      { 'x' => 'alpha' })
    assert_valid(
      [ { 'field' => 'x', 'has' => 'a' } ],
      { 'x' => { 'a' => 1 } })
    assert_valid(
      [ { 'field' => 'x', 'has' => 'a, b' } ],
      { 'x' => { 'a' => 1, 'b' => 2 } })
    assert_valid(
      [ { 'field' => 'x', 'has' => %w[ a b ] } ],
      { 'x' => { 'a' => 1, 'b' => 2 } })

    assert_not_valid(
      [ { 'field' => '.', 'has' => 'x' } ],
      {})
    assert_not_valid(
      [ { 'field' => 'x', 'has' => 'b' } ],
      { 'x' => { 'a' => 1 } })
    assert_not_valid(
      [ { 'field' => 'x', 'has' => 'a, c' } ],
      { 'x' => { 'a' => 1, 'b' => 2 } })
    assert_not_valid(
      [ { 'field' => 'x', 'has' => %w[ a c ] } ],
      { 'x' => { 'a' => 1, 'b' => 2 } })
  end

  def test_has__elts

    assert_valid(
      [ { 'field' => 'x', 'has' => 'a' } ],
      { 'x' => %w[ a b c ] })
    assert_valid(
      [ { 'field' => 'x', 'has' => 'a, b' } ],
      { 'x' => %w[ a b c ] })
    assert_valid(
      [ { 'field' => 'x', 'has' => %w[ a b ] } ],
      { 'x' => %w[ a b c ] })

    assert_not_valid(
      [ { 'field' => 'x', 'has' => 'd' } ],
      { 'x' => %w[ a b c ] })
    assert_not_valid(
      [ { 'field' => 'x', 'has' => 'a, d' } ],
      { 'x' => %w[ a b c ] })
    assert_not_valid(
      [ { 'field' => 'x', 'has' => %w[ a d ] } ],
      { 'x' => %w[ a b c ] })
  end

  def test_includes

    assert_valid(
      [ { 'field' => 'x', 'includes' => 'a' } ],
      { 'x' => %w[ a b c ] })

    assert_not_valid(
      [ { 'field' => 'x', 'includes' => 'z' } ],
      { 'x' => %w[ a b c ] })
    assert_not_valid(
      [ { 'field' => 'x', 'includes' => 'z' } ],
      { 'x' => 'abcz' })
  end

  def test_includes__value

    assert_valid(
      [ { 'field' => 'x', 'includes' => 1 } ],
      { 'x' => { 'a' => 1 } })

    assert_not_valid(
      [ { 'field' => 'x', 'includes' => '1' } ],
      { 'x' => { 'a' => 1 } })
  end

  def test_valid

    # 'valid' can be used in conjunction with the dollar notation
    #
    # field => 'x', 'valid' => '${v:accept}'

    assert_valid(
      [ { 'field' => 'x', 'valid' => true } ],
      {})
    assert_valid(
      [ { 'field' => 'x', 'valid' => 'true' } ],
      {})

    assert_not_valid(
      [ { 'field' => 'x', 'valid' => false } ],
      {})
    assert_not_valid(
      [ { 'field' => 'x', 'valid' => 'false' } ],
      {})
    assert_not_valid(
      [ { 'field' => 'x', 'valid' => 'nada' } ],
      {})
  end

  def test_cumulation

    assert_valid(
      [ { 'field' => 'x', 't' => 'array', 'has' => 'a' } ],
      { 'x' => %w[ a b c ] })

    assert_not_valid(
      [ { 'field' => 'x', 't' => 'hash', 'has' => 'a' } ],
      { 'x' => %w[ a b c ] })
  end

  def test_multiple_validations

    assert_not_valid(
      [
        { 'field' => 'x', 't' => 'array', 'has' => 1 },
        { 'field' => 'y', 't' => 'string' }
      ],
      {
        'x' => %w[ a b c ],
        'y' => true
      },
      :deviations => 2)

    assert_equal [
      [ { "has" => 1, "field" => "x", "t" => "array"}, "x", [ "a", "b", "c" ] ],
      [ { "field" => "y", "t" => "string" }, "y", true ]
    ], @deviations
      # not super happy with this @breaks thing
  end

  # when :no_raise => true and the validation fails, an array is returned
  # listing the 'deviations'
  #
  def test_no_raise

    r = Ruote.filter(
      [ { 'field' => 'x', 't' => 'hash', 'has' => 'a' } ],
      { 'x' => %w[ a b c ] },
      :no_raise => true)

    assert_equal(
      [ [ { "has" => "a", "field" => "x", "t" => "hash"}, "x", [ "a", "b", "c" ] ] ],
      r)
  end

  # Data passes through the filter untouched.
  #
  def test_no_raise_empty_result

    r = Ruote.filter(
      [ { 'field' => 'x', 't' => 'array', 'has' => 'a' } ],
      { 'x' => %w[ a b c ] },
      :no_raise => true)

    assert_equal(
      { 'x' => %w[ a b c ] },
      r)
  end

  #
  # flatten_keys tests

  def test_flatten_keys

    assert_equal(
      [
        'a',
        'c',
        'c.d',
        'c.f',
        'c.f.l',
        'c.f.n',
        'c.f.n.0',
        'c.f.n.1',
        'c.f.n.2',
        'c.g',
        'c.g.0',
        'c.g.0.i',
        'c.g.1',
        'h',
        'h.0',
        'h.1',
        'h.2'
      ],
      Ruote.flatten_keys({
        'a' => 'b',
        'c' => {
          'd' => 'e',
          'f' => {
            'l' => 'm',
            'n' => [ 1, 2, 3 ]
          },
          'g' => [
            { 'i' => 'j' },
            'k'
          ]
        },
        'h' => [
          1, 2, 3
        ]
      }))
  end

  def test_top_level_or

    filter = [
      { 'field' => 'x', 'type' => 'string' },
      { 'field' => 'y', 'type' => 'number' },
      'or',
      { 'field' => 'z', 'type' => 'bool' }
    ]

    assert_valid(filter, { 'x' => 'whatever', 'y' => 1 })
    assert_valid(filter, { 'z' => true })
    assert_valid(filter, { 'x' => -9, 'z' => false })
    assert_valid(filter, { 'x' => 'ah', 'y' => 2 })

    assert_not_valid(filter, { 'x' => 'whatever', 'y' => 'notanumber' })
    assert_not_valid(filter, { 'z' => 'notabool' })
    assert_not_valid(filter, { 'x' => 'x', 'z' => 'nada' })

    filter = [
      [ { 'field' => 'x', 'type' => 'string' },
        { 'field' => 'y', 'type' => 'number' } ],
      [ { 'field' => 'z', 'type' => 'bool' } ]
    ]

    assert_valid(filter, { 'x' => 'whatever', 'y' => 1 })
    assert_valid(filter, { 'z' => true })
    assert_valid(filter, { 'x' => -9, 'z' => false })
    assert_valid(filter, { 'x' => 'ah', 'y' => 2 })
  end

  def test_top_level_or_and_pipe_field

    filter = [
      { 'field' => 'x|params.x', 'type' => 'string' },
      'or',
      { 'field' => 'y|params.y', 'type' => 'bool' }
    ]

    assert_valid(filter, { 'x' => 'out' })
    assert_valid(filter, { 'params' => { 'x' => 'in' } })
    assert_valid(filter, { 'y' => true })
    assert_valid(filter, { 'params' => { 'y' => false } })

    assert_not_valid(filter, { 'y' => 'out' })
    assert_not_valid(filter, { 'params' => { 'y' => 'in' } })
    assert_not_valid(filter, {})
  end

  def test_misc_neutralization

    assert_valid(
      [ { :field => 'x', :type => :string } ], { 'x' => 'deux' })
    assert_valid(
      [ { :field => 'x', 'smatch' => /de/ } ], { 'x' => 'deux' })
  end
end

