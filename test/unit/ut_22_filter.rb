
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

    assert_equal(result, Ruote.filter(filter, hash))
  end

  def assert_valid (filter, hash)

    Ruote.filter(filter, hash)
    assert true
  end

  def assert_not_valid (filter, hash)

    assert_raise Ruote::ValidationError do
      Ruote.filter(filter, hash)
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
end

