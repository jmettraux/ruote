
#
# testing ruote
#
# Mon Dec 14 15:03:13 JST 2009
#

require File.join(File.dirname(__FILE__), %w[ .. test_helper.rb ])
require File.join(File.dirname(__FILE__), %w[ .. functional storage_helper.rb ])


class UtStorage < Test::Unit::TestCase

  def setup
    @s = determine_storage({})
    @s.h['dogfood'] = {} if @s.respond_to?(:h)
    @s.put(
      '_id' => 'toto',
      'type' => 'dogfood',
      'message' => 'testing')
  end
  def teardown
    @s.get_many('dogfood').each { |d| @s.delete(d) }
  end

  def test_get_configuration

    assert_not_nil @s.get_configuration('engine')
  end

  def test_get

    h = @s.get('dogfood', 'toto')

    assert_not_nil h['_rev']

    h = @s.get('dogfood', 'nada')

    assert_nil h
  end

  def test_put

    @s.put('_id' => 'nada', 'type' => 'dogfood', 'message' => 'testing again')

    h = @s.get('dogfood', 'nada')

    assert_not_nil h['_rev']
  end

  def test_put_fail

    r = @s.put('_id' => 'toto', 'type' => 'dogfood', 'message' => 'more')

    assert_equal 'toto', r['_id']
    assert_not_nil r['_rev']
  end

  def test_put_update_rev

    doc = { '_id' => 'ouinouin', 'type' => 'dogfood', 'message' => 'more' }

    r = @s.put(doc, :update_rev => true)

    assert_not_nil doc['_rev']
  end

  def test_delete_fail

    assert_raise(ArgumentError) do
      @s.delete('_id' => 'toto')
    end
  end

  def test_delete

    doc = @s.get('dogfood', 'toto')

    r = @s.delete(doc)

    assert_nil r
  end

  def test_delete_missing

    r = @s.delete('_id' => 'x', '_rev' => '12-13231123132', 'type' => 'dogfood')

    assert_equal true, r
  end

  def test_keys_should_be_string

    require 'yajl' rescue require 'json'
    Rufus::Json.detect_backend

    doc = { '_id' => 'h0', 'type' => 'dogfood', :m0 => :z, :m1 => [ :a, :b ] }

    @s.put(doc)

    doc = @s.get('dogfood', 'h0')

    assert_equal 'z', doc['m0']
    assert_equal %w[ a b ], doc['m1']
  end
end

