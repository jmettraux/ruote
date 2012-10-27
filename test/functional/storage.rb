
#
# testing ruote
#
# Mon Dec 14 15:03:13 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)
require_json
require File.expand_path('../../functional/storage_helper', __FILE__)
require File.expand_path('../../functional/signals', __FILE__)
require 'ruote'


# Please note:

# Operations return something trueish when they fail and nil
# when they succeed.
#
# The pattern is: when it fails because the document passed as argument is
# outdated, you will receive the current version of the document (trueish),
# when it fails because the document is gone (deleted meanwhile), you will
# receive true (which is obviously trueish).

class FtStorage < Test::Unit::TestCase

  #
  # test preparation

  def setup

    @s = determine_storage({})
    @s = @s.storage if @s.respond_to?(:storage)

    %w[ errors expressions msgs workitems ].each do |t|
      @s.purge_type!(t)
    end
  end

  def teardown

    return unless @s

    @s.purge!

    @s.shutdown
  end

  #
  # helpers

  def put_toto_doc

    @s.put('_id' => 'toto', 'type' => 'errors', 'message' => 'testing')
  end

  def get_toto_doc

    @s.get('errors', 'toto')
  end

  #
  # the tests

  # === put

  # When successful, #put returns nil.
  #
  def test_put

    doc = { '_id' => 'toto', 'type' => 'errors', 'message' => 'testing' }

    r = @s.put(doc)

    assert_nil r

    assert_nil doc['_rev']
    assert_nil doc['put_at']

    doc = @s.get('errors', 'toto')

    assert_not_nil doc['_rev']
    assert_not_nil doc['put_at']

    assert_equal 'testing', doc['message']
  end

  # When a document with the same _id and type already existent, the put
  # doesn't happen and #put returns that already existing document.
  #
  def test_put_when_already_existent

    put_toto_doc

    doc = { '_id' => 'toto', 'type' => 'errors', 'message' => 'two' }

    r = @s.put(doc)

    assert_match /Hash$/, r.class.name
    assert_not_nil r['_rev']
    assert_not_nil r['put_at']

    assert_nil doc['_rev']
    assert_nil doc['put_at']
  end

  # A successful reput (_id/type/_rev do match) returns nil.
  #
  def test_reput

    put_toto_doc

    d0 = get_toto_doc

    d0['message'] = 'test_reput'

    r = @s.put(d0)

    assert_nil r

    d1 = get_toto_doc

    assert_not_equal d1['_rev'], d0['_rev']
    assert_not_equal d1['put_at'], d0['put_at']

    assert_equal 'test_reput', d1['message']
  end

  # A reput with the wrong rev (our document is outdated probably) will
  # not happen and #put will return the current (newest probably) document.
  #
  def test_reput_fail_wrong_rev

    put_toto_doc

    d1 = get_toto_doc

    rev = d1['_rev']

    @s.put(d1.merge('message' => 'x'))

    d2 = get_toto_doc

    r = @s.put(d2.merge('_rev' => rev, 'message' => 'y'))

    assert_not_nil r
    assert_not_equal d1['_rev'], d2['_rev']
    assert_equal 'x', d2['message']
  end

  # Attempting to put a document that is gone (got deleted meanwhile) will
  # return true.
  #
  def test_reput_fail_gone

    put_toto_doc

    doc = get_toto_doc

    @s.delete(doc)

    r = @s.put(doc)

    assert_equal true, r
  end

  # Attempting to put a document with a _rev directly will raise an
  # ArgumentError.
  #
  def test_put_doc_with_rev

    put_toto_doc; doc = get_toto_doc
      # just to get a valid _rev

    r = @s.put(
      '_id' => 'doc_with_rev', 'type' => 'errors', '_rev' => doc['_rev'])

    assert_equal true, r
  end

  # #put takes an optional :update_rev. When set to true and the put
  # succeeds, the _rev and the put_at of the [local] document are set/updated.
  #
  def test_put_update_rev_new_document

    doc = { '_id' => 'urev', 'type' => 'errors' }

    r = @s.put(doc, :update_rev => true)

    assert_nil r
    assert_not_nil doc['_rev']
    assert_not_nil doc['put_at']
  end

  # When putting a document with the :update_rev option set, the just put
  # document will get the new _rev (and the put_at)
  #
  def test_put_update_rev_existing_document

    put_toto_doc; doc = get_toto_doc

    initial_rev = doc['_rev']
    initial_put_at = doc['put_at']

    r = @s.put(doc, :update_rev => true)

    assert_nil r
    assert_not_nil initial_rev
    assert_not_nil initial_put_at
    assert_not_nil doc['_rev']
    assert_not_equal doc['_rev'], initial_rev
    assert_not_nil doc['put_at']
    assert_not_equal doc['put_at'], initial_put_at
  end

  # put_at and _rev should not repeat
  #
  def test_put_sequence

    revs = []
    doc = { '_id' => 'putseq', 'type' => 'errors' }

    77.times do |i|

      r = @s.put(doc)
      doc = @s.get('errors', 'putseq')

      revs << doc['_rev']

      assert_nil r
      assert_not_nil doc['put_at']
      assert_equal i + 1, revs.uniq.size
    end
  end

  # Be lenient with the input (accept symbols, but turn them into strings).
  #
  def test_put_turns_symbols_into_strings

    r = @s.put('_id' => 'skeys', 'type' => 'errors', :a => :b)

    assert_nil r

    doc = @s.get('errors', 'skeys')

    return if doc.class != Hash
      # MongoDB uses BSON::OrderedHash which is happy with symbols...

    assert_equal 'b', doc['a']
  end

  # === get

  # Getting a non-existent document returns nil.
  #
  def test_get_non_existent

    assert_nil @s.get('errors', 'nemo')
  end

  # Getting a document returns it (well the most up-to-date revision of it).
  #
  def test_get

    put_toto_doc

    doc = @s.get('errors', 'toto')

    doc.delete('_rev')
    doc.delete('put_at')
    doc.delete('_wfid') # ruote-mon

    assert_equal(
      { '_id' => 'toto', 'type' => 'errors', 'message' => 'testing' },
      doc)
  end

  # === delete

  # When successful, #delete returns nil (like the other methods...).
  #
  def test_delete

    put_toto_doc

    doc = @s.get('errors', 'toto')

    r = @s.delete(doc)

    assert_equal nil, r

    doc = @s.get('errors', 'toto')

    assert_equal nil, doc
  end

  # When attempting to delete a document and that document argument has no
  # _rev, it will raise an ArgumentError.
  #
  def test_delete_document_without_rev

    assert_raise(
      ArgumentError, "can't delete doc without _rev"
    ) do
      @s.delete('_id' => 'without_rev', 'type' => 'errors')
    end
  end

  # Deleting a document that doesn't exist returns true.
  #
  def test_delete_non_existent_document

    put_toto_doc; doc = get_toto_doc
      # just to get a valid _rev

    r = @s.delete('_id' => 'ned', 'type' => 'errors', '_rev' => doc['_rev'])

    assert_equal true, r
  end

  # Deleting a document that is gone (got deleted meanwhile) returns true.
  #
  def test_delete_gone_document

    put_toto_doc
    doc = get_toto_doc
    @s.delete(doc)

    r = @s.delete(doc)

    assert_equal true, r
  end

  # === get_many

  # Get many documents at once, use a string or regex key, or not.
  #
  def test_get_many

    load_30_errors

    assert_equal 30, @s.get_many('errors').size
    assert_equal 0, @s.get_many('errors', '7').size
    assert_equal 1, @s.get_many('errors', '07').size
    assert_equal 1, @s.get_many('errors', /!07$/).size
    assert_equal 30, @s.get_many('errors', /^yy!/).size
    assert_equal 30, @s.get_many('errors', /y/).size

    assert_equal 'yy!07', @s.get_many('errors', '07').first['_id']
    assert_equal 'yy!07', @s.get_many('errors', /!07/).first['_id']
  end

  # Get many documents at once, use an array of string or regex keys.
  #
  def test_get_many_array_of_keys

    load_30_errors

    assert_equal 30, @s.get_many('errors').size
    assert_equal 2, @s.get_many('errors', [ '07', '08' ]).size
    assert_equal 2, @s.get_many('errors', [ /!07$/, /!08$/ ]).size

    assert_equal(
      %w[ yy!07 yy!08 ],
      @s.get_many('errors', [ '07', '08' ]).collect { |d| d['_id'] }.sort)
    assert_equal(
      %w[ yy!07 yy!08 ],
      @s.get_many('errors', [ /!07$/, /!08$/ ]).collect { |d| d['_id'] }.sort)
  end

  # Limit the number of documents received.
  #
  def test_get_many_limit

    load_30_errors

    assert_equal 10, @s.get_many('errors', nil, :limit => 10).size
  end

  # Count the documents (in a type).
  #
  def test_get_many_count

    load_30_errors

    assert_equal 30, @s.get_many('errors', nil, :count => true)
  end

  # Paginate documents.
  #
  def test_get_many_skip_and_limit

    load_30_errors

    assert_equal(
      %w[ yy!01 yy!02 yy!03 yy!04 ],
      @s.get_many(
        'errors', nil, :skip => 0, :limit => 4
      ).collect { |d| d['_id'] })
    assert_equal(
      %w[ yy!04 yy!05 yy!06 ],
      @s.get_many(
        'errors', nil, :skip => 3, :limit => 3
      ).collect { |d| d['_id'] })
  end

  # Pagination and :descending are not incompatible.
  #
  def test_get_many_skip_limit_and_reverse

    load_30_errors

    assert_equal(
      %w[ yy!30 yy!29 yy!28 ],
      @s.get_many(
        'errors', nil, :skip => 0, :limit => 3, :descending => true
      ).collect { |d| d['_id'] })
    assert_equal(
      %w[ yy!27 yy!26 yy!25 ],
      @s.get_many(
        'errors', nil, :skip => 3, :limit => 3, :descending => true
      ).collect { |d| d['_id'] })
  end

  # === purge!

  # Purge removes all the documents in the storage.
  #
  def test_purge

    put_toto_doc

    assert_equal 1, @s.get_many('errors').size

    @s.purge!

    assert_equal 0, @s.get_many('errors').size
  end

  # === reserve

  # Making sure that Storage#reserve(msg) returns true once and only once
  # for a given msg. Stresses the storage for a while and then checks
  # for collisions.
  #
  def test_reserve

    # TODO: eventually return here if the storage being tested has
    #       no need for a real reserve implementation (ruote-swf for example).

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

  # === ids

  # Storage#ids(type) returns all the ids present for a document type, in
  # sorted order.
  #
  def test_ids

    ids = load_30_errors

    assert_equal ids.sort, @s.ids('errors')
  end

  # === dump

  # #dump returns a string representation of the storage's content. Warning,
  # this is a debug/test method.
  #
  def test_dump

    load_30_errors

    dump = @s.dump('errors')

    assert_match /^[ -] _id: yy!01\n/, dump
    assert_match /^[ -] _id: yy!21\n/, dump
  end

  # === clear

  # #clear clears the storage
  #
  def test_clear

    put_toto_doc

    assert_equal 1, @s.get_many('errors').size

    @s.clear

    assert_equal 0, @s.get_many('errors').size
  end

  # === remove_process

  # Put documents for process 0 and process 1, remove_process(1), check that
  # only documents for process 0 are remaining.
  #
  # Don't forget to deal with trackers and schedules.
  #
  def test_remove_process

    @s.purge_type!('errors')
    ts = @s.get_trackers
    @s.delete(ts) if ts['_rev']

    dboard = Ruote::Dashboard.new(Ruote::Worker.new(@s))
    dboard.noisy = ENV['NOISY'] == 'true'

    dboard.register :human, Ruote::StorageParticipant

    pdef = Ruote.define do
      concurrence do
        wait '1d'
        human
        listen :to => 'bob'
        error 'nada'
      end
    end

    wfid0 = dboard.launch(pdef)
    wfid1 = dboard.launch(pdef)

    dboard.wait_for('error_intercepted')
    dboard.wait_for('error_intercepted')

    assert_equal 12, @s.get_many('expressions').size
    assert_equal 2, @s.get_many('schedules').size
    assert_equal 2, @s.get_many('workitems').size
    assert_equal 2, @s.get_many('errors').size
    assert_equal 2, @s.get_trackers['trackers'].size

    @s.remove_process(wfid0)

    assert_equal 6, @s.get_many('expressions').size
    assert_equal 1, @s.get_many('schedules').size
    assert_equal 1, @s.get_many('workitems').size
    assert_equal 1, @s.get_many('errors').size
    assert_equal 1, @s.get_trackers['trackers'].size

  ensure
    dboard.shutdown rescue nil
  end

  # === configuration

  # Simply getting the engine configuration should work.
  #
  def test_get_configuration

    assert_not_nil @s.get_configuration('engine')
  end

  # The initial configuration passed when initializing the storage overrides
  # any previous configuration.
  #
  def test_override_configuration

    determine_storage('house' => 'taira', 'domain' => 'harima')
    s = determine_storage('house' => 'minamoto')

    assert_equal 'minamoto', s.get_configuration('engine')['house']
    assert_equal nil, s.get_configuration('engine')['domain']
  end

  # Testing the 'preserve_configuration' option for storage initialization.
  #
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

  # === query workitems

  # Query by workitem field.
  #
  def test_by_field

    return unless @s.respond_to?(:by_field)

    load_workitems

    assert_equal 3, @s.by_field('workitems', 'place', 'kyouto').size
    assert_equal 1, @s.by_field('workitems', 'place', 'sendai').size

    assert_equal(
      Ruote::Workitem, @s.by_field('workitems', 'place', 'sendai').first.class)
  end

  # Query by participant name.
  #
  def test_by_participant

    return unless @s.respond_to?(:by_participant)

    load_workitems

    assert_equal 2, @s.by_participant('workitems', 'fujiwara', {}).size
    assert_equal 1, @s.by_participant('workitems', 'shingen', {}).size

    assert_equal(
      Ruote::Workitem, @s.by_participant('workitems', 'shingen', {}).first.class)
  end

  # General #query_workitems method.
  #
  def test_query_workitems

    return unless @s.respond_to?(:query_workitems)

    load_workitems

    assert_equal 3, @s.query_workitems('place' => 'kyouto').size
    assert_equal 1, @s.query_workitems('place' => 'kyouto', 'at' => 'kamo').size

    assert_equal(
      Ruote::Workitem, @s.query_workitems('place' => 'kyouto').first.class)
  end

  # === misc

  # Simply make sure the storage (well, at least its "error" type) is empty.
  #
  def test_starts_empty

    assert_equal 0, @s.get_many('errors').size
  end

  protected

  #
  # helpers

  def load_30_errors

    (1..30).to_a.shuffle.collect do |i|

      id = sprintf('yy!%0.2d', i)

      @s.put(
        '_id' => id,
        'type' => 'errors',
        'msg' => "whatever #{i}",
        'wfid' => id.split('!').last)

      id
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

