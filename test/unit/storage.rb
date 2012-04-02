
#
# testing ruote
#
# Mon Dec 14 15:03:13 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require_json

require File.expand_path('../../functional/storage_helper', __FILE__)

require 'ruote'


#
# note : using the 'errors' type, but this test is about generic storage, not
#        about errors per se.
#

class UtStorage < Test::Unit::TestCase

  def setup

    @s = determine_storage({})
    @s = @s.storage if @s.respond_to?(:storage)

    #@s.add_type('errors')

    @s.purge_type!('errors')
    @s.purge_type!('expressions')
    @s.purge_type!('msgs')
    @s.purge_type!('workitems')

    @s.put(
      '_id' => 'toto',
      'type' => 'errors',
      'message' => 'testing')
  end

  def teardown

    return unless @s

    @s.purge_type!('errors')
    @s.purge_type!('expressions')
    @s.purge_type!('msgs')
    @s.purge_type!('workitems')

    @s.shutdown
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

    return if doc.class != Hash
      # MongoDB uses BSON::OrderedHash which is happy with symbols...

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

  def test_get_many_multi_keys

    28.times do |i|
      @s.put(
        '_id' => "yy!#{i}",
        'type' => 'errors',
        'wfid' => i.to_s,
        'msg' => "anyway #{i}")
    end

    assert_equal 29, @s.get_many('errors').size
    assert_equal 2, @s.get_many('errors', [ '7', '8' ]).size
    assert_equal 2, @s.get_many('errors', [ /!7$/, /!8$/ ]).size
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

  def test_ids_and_errors

    load_30_errors

    assert_equal 31, @s.ids('errors').length
  end

  def test_ids_are_sorted

    load_30_errors

    assert_equal @s.ids('errors').sort, @s.ids('errors')
  end

  def test_reserve

    taoe = Thread.abort_on_exception
    Thread.abort_on_exception = true

    reserved = []
    threads = []

    threads << Thread.new do
      i = 0
      loop do
        @s.put_msg('launch', 'tree' => i)
        i = i + 1
      end
    end

    2.times do

      threads << Thread.new do
        loop do
          msgs = @s.get_msgs
          msgs[0, 100].each do |msg|
            next if msg['tree'].nil?
            next unless @s.reserve(msg)
            if reserved.include?(msg['tree'])
              puts "=" * 80
              p [ :dbl, :r, msg['_rev'], :t, msg['tree'] ]
            end
            reserved << msg['tree']
            sleep(rand * 0.01)
          end
        end
      end
    end

    sleep 7

    threads.each { |t| t.terminate }

    Thread.abort_on_exception = taoe

    assert_equal false, reserved.empty?
    assert_equal reserved.size, reserved.uniq.size
  end

  def test_by_field

    return unless @s.respond_to?(:by_field)

    load_workitems

    assert_equal 3, @s.by_field('workitems', 'place', 'kyouto').size
    assert_equal 1, @s.by_field('workitems', 'place', 'sendai').size

    assert_equal(
      Ruote::Workitem, @s.by_field('workitems', 'place', 'sendai').first.class)
  end

  def test_by_participant

    return unless @s.respond_to?(:by_participant)

    load_workitems

    assert_equal 2, @s.by_participant('workitems', 'fujiwara', {}).size
    assert_equal 1, @s.by_participant('workitems', 'shingen', {}).size

    assert_equal(
      Ruote::Workitem, @s.by_participant('workitems', 'shingen', {}).first.class)
  end

  def test_query_workitems

    return unless @s.respond_to?(:query_workitems)

    load_workitems

    assert_equal 3, @s.query_workitems('place' => 'kyouto').size
    assert_equal 1, @s.query_workitems('place' => 'kyouto', 'at' => 'kamo').size

    assert_equal(
      Ruote::Workitem, @s.query_workitems('place' => 'kyouto').first.class)
  end

  def test_override_configuration

    determine_storage('house' => 'taira')
    s = determine_storage('house' => 'minamoto')

    assert_equal 'minamoto', s.get_configuration('engine')['house']
  end

  def test_preserve_configuration

    return if @s.class == Ruote::HashStorage
      # this test makes no sense with an in-memory hash

    determine_storage(
      'house' => 'taira')
    s = determine_storage(
      'house' => 'minamoto', 'preserve_configuration' => true)

    assert_equal 'taira', s.get_configuration('engine')['house']

    # if this test is giving a
    # "NoMethodError: undefined method `[]' for nil:NilClass"
    # for ruote-dm, comment out the auto_upgrade! block in
    # ruote-dm/test/functional_connection.rb
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

  def put_workitem(wfid, participant_name, fields)

    @s.put(
      'type' => 'workitems',
      '_id' => "wi!0_0!12ff!#{wfid}",
      'participant_name' => participant_name,
      'wfid' => wfid,
      'fields' => fields)
  end

  def load_workitems

    put_workitem(
      '20110218-nadanada', 'fujiwara', 'place' => 'kyouto')
    put_workitem(
      '20110218-nedenada', 'fujiwara', 'place' => 'kyouto', 'at' => 'kamo')
    put_workitem(
      '20110218-nadanodo', 'taira', 'place' => 'kyouto')
    put_workitem(
      '20110218-nodonada', 'date', 'place' => 'sendai')
    put_workitem(
      '20110218-nadanudu', 'shingen', 'place' => 'nagoya')
  end
end

