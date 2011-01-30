
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

  def test_remove

    assert_equal(
      {},
      Ruote.filter(
        [
          { 'field' => 'x', 'remove' => true }
        ],
        { 'x' => 'y' }))

    assert_equal(
      { 'x' => {} },
      Ruote.filter(
        [
          { 'field' => 'x.y', 'remove' => true }
        ],
        { 'x' => { 'y' => 'z' } }))
  end

  def test_default

    assert_equal(
      { 'x' => 1 },
      Ruote.filter(
        [
          { 'field' => 'x', 'default' => 1 }
        ],
        {}))

    assert_equal(
      { 'x' => 2 },
      Ruote.filter(
        [
          { 'field' => 'x', 'default' => 1 }
        ],
        { 'x' => 2 }))

    assert_equal(
      { 'x' => { 'y' => 1 } },
      Ruote.filter(
        [
          { 'field' => 'x.y', 'default' => 1 }
        ],
        { 'x' => {} }))

    assert_equal(
      { 'x' => { 'y' => 2 } },
      Ruote.filter(
        [
          { 'field' => 'x.y', 'default' => 1 }
        ],
        { 'x' => { 'y' => 2 } }))

    assert_equal(
      { 'x' => { 'y' => 1 } },
      Ruote.filter(
        [
          { 'field' => 'x', 'default' => {} },
          { 'field' => 'x.y', 'default' => 1 }
        ],
        {}))
  end
end

