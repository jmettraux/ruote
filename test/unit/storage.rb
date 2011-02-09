
#
# testing ruote
#
# Mon Dec 14 15:03:13 JST 2009
#

require File.join(File.dirname(__FILE__), %w[ .. test_helper.rb ])

require_json

require File.join(File.dirname(__FILE__), %w[ .. functional storage_helper.rb ])

require 'ruote/fei'


#
# note : using the 'errors' type, but this test is about generic storage, not
#        about errors per se.
#

class UtStorage < Test::Unit::TestCase

  def setup

    @s = determine_storage({})

    #@s.add_type('errors')

    @s.put(
      '_id' => 'toto',
      'type' => 'errors',
      'message' => 'testing')
  end

  def teardown

    %w[ error msgs ].each do |type|
      begin
        @s.get_many('errors').each { |d| @s.delete(d) }
      rescue
        # ignore
      end
    end
  end

  def test_get_configuration

    assert_not_nil @s.get_configuration('engine')
  end

  def test_get

    h = @s.get('errors', 'toto')

    assert_not_nil h['_rev']

    h = @s.get('errors', 'nada')

    assert_nil h
  end

  def test_put

    doc =  {
      '_id' => 'test_put', 'type' => 'errors', 'message' => 'testing (2)' }

    @s.put(doc)

    assert_nil doc['_rev']

    h = @s.get('errors', 'test_put')

    assert_not_nil h['_rev']
    assert_not_nil h['put_at']
  end

  def test_put_fail

    r = @s.put('_id' => 'toto', 'type' => 'errors', 'message' => 'more')

    assert_equal 'toto', r['_id']
    assert_not_nil r['_rev']
  end

  def test_put_update_rev

    doc = { '_id' => 'tpur', 'type' => 'errors', 'message' => 'more' }

    r = @s.put(doc, :update_rev => true)

    assert_not_nil doc['_rev']
  end

  def test_put_put_and_put

    doc = { '_id' => 'whiskas', 'type' => 'errors', 'message' => 'miam' }

    r = @s.put(doc)
    doc = @s.get('errors', 'whiskas')

    r = @s.put(doc)
    assert_nil r

    doc = @s.get('errors', 'whiskas')

    assert_not_nil doc['put_at']

    r = @s.put(doc)
    assert_nil r
  end

  def test_put_update_rev_twice

    doc = { '_id' => 'tpurt', 'type' => 'errors', 'message' => 'more' }

    r = @s.put(doc, :update_rev => true)
    assert_nil r

    doc = { '_id' => 'tpurt', 'type' => 'errors', 'message' => 'more' }

    r = @s.put(doc, :update_rev => true)
    assert_not_nil r
  end

  def test_delete_fail

    # missing _rev

    assert_raise(ArgumentError) do
      @s.delete('_id' => 'toto')
    end
  end

  def test_delete

    doc = @s.get('errors', 'toto')

    r = @s.delete(doc)

    assert_nil r
  end

  def test_delete_missing

    r = @s.delete('_id' => 'x', '_rev' => '12-13231123132', 'type' => 'errors')

    assert_equal true, r
  end

  def test_keys_should_be_string

    doc = { '_id' => 'h0', 'type' => 'errors', :m0 => :z, :m1 => [ :a, :b ] }

    @s.put(doc)

    doc = @s.get('errors', 'h0')

    assert_equal 'z', doc['m0']
    assert_equal %w[ a b ], doc['m1']
  end

  # Updating a gone document must result in a 'true' reply.
  #
  def test_put_gone

    h = @s.get('errors', 'toto')

    assert_nil @s.delete(h)

    h['colour'] = 'blue'

    assert_equal true, @s.put(h)
  end

  def test_purge_type

    @s.purge_type!('errors')

    assert_equal 0, @s.get_many('errors').size
  end

  def test_clear

    @s.clear

    assert_equal 0, @s.get_many('errors').size
  end

  #def test_purge
  #  @s.purge!
  #  assert_equal 0, @s.get_many('errors').size
  #end

  def test_ids

    @s.put('_id' => 't_ids0', 'type' => 'errors', 'message' => 'testing')
    @s.put('_id' => 't_ids1', 'type' => 'errors', 'message' => 'testing')
    @s.put('_id' => 't_ids2', 'type' => 'errors', 'message' => 'testing')

    assert_equal %w[ t_ids0 t_ids1 t_ids2 toto ], @s.ids('errors').sort
  end

  def test_get_many

    30.times do |i|
      @s.put(
        '_id' => "xx!#{i}",
        'type' => 'errors',
        'wfid' => i.to_s,
        'msg' => "whatever #{i}")
    end

    assert_equal 31, @s.get_many('errors').size
    assert_equal 1, @s.get_many('errors', '7').size
    assert_equal 1, @s.get_many('errors', /!7$/).size
    assert_equal 30, @s.get_many('errors', /^xx!/).size
    assert_equal 30, @s.get_many('errors', /x/).size
    assert_equal 10, @s.get_many('errors', nil, :limit => 10).size
  end

  def test_get_many_options

    load_30_errors

    # limit

    assert_equal 10, @s.get_many('errors', nil, :limit => 10).size

    # count

    assert_equal 31, @s.get_many('errors', nil, :count => true)

    # skip and limit

    assert_equal(
      %w[ toto yy!00 yy!01 yy!02 ],
      @s.get_many(
        'errors', nil, :skip => 0, :limit => 4
      ).collect { |d| d['_id'] })
    assert_equal(
      %w[ yy!02 yy!03 yy!04 ],
      @s.get_many(
        'errors', nil, :skip => 3, :limit => 3
      ).collect { |d| d['_id'] })

    # skip, limit and reverse

    assert_equal(
      %w[ yy!29 yy!28 yy!27 ],
      @s.get_many(
        'errors', nil, :skip => 0, :limit => 3, :descending => true
      ).collect { |d| d['_id'] })
    assert_equal(
      %w[ yy!29 yy!28 yy!27 ],
      @s.get_many(
        'errors', nil, :skip => 0, :limit => 3, :descending => true
      ).collect { |d| d['_id'] })
  end

  def test_dump

    load_30_errors

    assert @s.dump('errors').length > 0
  end

  def test_ids

    load_30_errors

    assert_equal 31, @s.ids('errors').length
  end

  def test_ids_are_sorted

    load_30_errors

    assert_equal @s.ids('errors').sort, @s.ids('errors')
  end

  def test_reserve

    reserved = []
    threads = []

    threads << Thread.new do
      loop do
        @s.put_msg('launch', 'tree' => 'nada')
      end
    end
    2.times do
      threads << Thread.new do
        loop do
          @s.get_msgs.each do |msg|
            sleep(rand * 0.02)
            reserved << msg['_id'] if @s.reserve(msg)
          end
        end
      end
    end

    sleep 7

    threads.each do |t|
      t.kill
    end

    assert reserved.size > 0

    assert_equal(
      reserved.uniq.size,
      reserved.size,
      "double reservations happened, not multi-worker safe")
  end

  protected

  def load_30_errors

    30.times do |i|
      @s.put(
        '_id' => sprintf("yy!%0.2d", i),
        'type' => 'errors',
        'msg' => "whatever #{i}")
    end
  end
end

