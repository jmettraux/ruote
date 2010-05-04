
#
# testing ruote
#
# Mon Dec 14 15:03:13 JST 2009
#

require File.join(File.dirname(__FILE__), %w[ .. test_helper.rb ])

require_json
require_patron

require File.join(File.dirname(__FILE__), %w[ .. functional storage_helper.rb ])


class UtStorage < Test::Unit::TestCase

  def setup
    @s = determine_storage({})
    @s.add_type('dogfood')
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

    doc =  { '_id' => 'nada', 'type' => 'dogfood', 'message' => 'testing (2)' }

    @s.put(doc)

    assert_nil doc['_rev']

    h = @s.get('dogfood', 'nada')

    assert_not_nil h['_rev']
    assert_not_nil h['put_at']
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

  def test_put_put_and_put

    doc = { '_id' => 'whiskas', 'type' => 'dogfood', 'message' => 'miam' }

    r = @s.put(doc)
    doc = @s.get('dogfood', 'whiskas')

    r = @s.put(doc)
    assert_nil r

    doc = @s.get('dogfood', 'whiskas')

    assert_not_nil doc['put_at']

    r = @s.put(doc)
    assert_nil r
  end

  def test_put_update_rev_twice

    doc = { '_id' => 'ouinouin', 'type' => 'dogfood', 'message' => 'more' }

    r = @s.put(doc, :update_rev => true)
    assert_nil r

    doc = { '_id' => 'ouinouin', 'type' => 'dogfood', 'message' => 'more' }

    r = @s.put(doc, :update_rev => true)
    assert_not_nil r
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

    doc = { '_id' => 'h0', 'type' => 'dogfood', :m0 => :z, :m1 => [ :a, :b ] }

    @s.put(doc)

    doc = @s.get('dogfood', 'h0')

    assert_equal 'z', doc['m0']
    assert_equal %w[ a b ], doc['m1']
  end

  # Updating a gone document must result in a 'true' reply.
  #
  def test_put_gone

    h = @s.get('dogfood', 'toto')

    assert_nil @s.delete(h)

    h['colour'] = 'blue'

    assert_equal true, @s.put(h)
  end

  def test_purge_type

    @s.purge_type!('dogfood')

    assert_equal 0, @s.get_many('dogfood').size
  end

  def test_ids

    @s.put('_id' => 'ouinouin', 'type' => 'dogfood', 'message' => 'testing')
    @s.put('_id' => 'nada', 'type' => 'dogfood', 'message' => 'testing')
    @s.put('_id' => 'estereo', 'type' => 'dogfood', 'message' => 'testing')

    assert_equal %w[ estereo nada ouinouin toto ], @s.ids('dogfood').sort
  end

  def test_get_many

    30.times do |i|
      @s.put('_id' => "xx!#{i}", 'type' => 'dogfood', 'msg' => "whatever #{i}")
    end

    assert_equal 31, @s.get_many('dogfood').size
    assert_equal 10, @s.get_many('dogfood', nil, :limit => 10).size
    assert_equal 1, @s.get_many('dogfood', /!7$/).size
    assert_equal 30, @s.get_many('dogfood', /^xx!/).size
    assert_equal 30, @s.get_many('dogfood', /x/).size
  end
end

