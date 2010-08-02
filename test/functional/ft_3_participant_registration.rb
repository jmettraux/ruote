
#
# testing ruote
#
# Mon May 18 22:25:57 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote'


class FtParticipantRegistrationTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant_register

    #noisy

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    wait_for(1)

    msg = logger.log.last
    assert_equal 'participant_registered', msg['action']
    assert_equal 'alpha', msg['regex']

    assert_equal(
      [ 'inpa_:alpha' ],
      @engine.context.plist.instantiated_participants.collect { |e| e.first })

    assert_equal(
      [ [ '^alpha$', 'inpa_:alpha' ] ],
      @engine.participant_list.collect { |pe| pe.to_a })
  end

  def test_double_registration

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end
    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    assert_equal 1, @engine.context.plist.send(:get_list)['list'].size
  end

  def test_register_and_return_participant

    pa = @engine.register_participant :alpha do |workitem|
    end

    assert_kind_of Ruote::BlockParticipant, pa
  end

  def test_participant_unregister_by_name

    #noisy

    @engine.register_participant :alpha do |workitem|
    end

    @engine.unregister_participant :alpha

    wait_for(2)
    Thread.pass

    msg = logger.log.last
    assert_equal 'participant_unregistered', msg['action']
    assert_equal '^alpha$', msg['regex']

    assert_equal 0, @engine.context.plist.instantiated_participants.size
  end

  def test_participant_unregister

    pa = @engine.register_participant :alpha do |workitem|
    end

    @engine.unregister_participant pa

    wait_for(2)

    msg = logger.log.last
    assert_equal 'participant_unregistered', msg['action']
    assert_equal '^alpha$', msg['regex']

    assert_equal 0, @engine.context.plist.instantiated_participants.size
  end

  class MyParticipant
    attr_reader :down
    def initialize
      @down = false
    end
    def shutdown
      @down = true
    end
  end

  def test_participant_shutdown

    alpha = @engine.register :alpha, MyParticipant.new

    @engine.context.plist.shutdown

    assert_equal true, alpha.down
  end

  def test_participant_list_of_names

    pa = @engine.register_participant :alpha do |workitem|
    end

    assert_equal [ '^alpha$' ], @engine.context.plist.names
  end

  def test_register_require_path

    rpath = File.join(
      File.dirname(__FILE__), "#{Time.now.to_f}_#{$$}_required_participant")
    path = "#{rpath}.rb"

    File.open(path, 'wb') do |f|
      f.write(%{
        class RequiredParticipant
          include Ruote::LocalParticipant
          def initialize (opts)
            @opts = opts
          end
          def consume (workitem)
            workitem.fields['message'] = @opts['message']
            reply(workitem)
          end
        end
      })
    end

    @engine.register_participant(
      :alfred,
      'RequiredParticipant',
      :require_path => rpath, :message => 'hello')

    assert_equal [ '^alfred$' ], @engine.context.plist.names

    # first run

    assert_equal(
      [ 'RequiredParticipant',
        { 'require_path' => rpath, 'message' => 'hello' } ],
      @engine.context.plist.lookup_info('alfred', nil))

    wfid = @engine.launch(Ruote.define { alfred })
    r = @engine.wait_for(wfid)

    assert_equal 'hello', r['workitem']['fields']['message']

    # second run

    File.open(path, 'wb') do |f|
      f.write(%{
        class RequiredParticipant
          include Ruote::LocalParticipant
          def initialize (opts)
            @opts = opts
          end
          def consume (workitem)
            workitem.fields['message'] = 'second run'
            reply(workitem)
          end
        end
      })
    end

    wfid = @engine.launch(Ruote.define { alfred })
    r = @engine.wait_for(wfid)

    # since it's a 'require', the code isn't reloaded

    assert_equal 'hello', r['workitem']['fields']['message']

    FileUtils.rm(path)
  end

  def test_reqister_load_path

    path = File.join(
      File.dirname(__FILE__), "#{Time.now.to_f}_#{$$}_loaded_participant.rb")

    File.open(path, 'wb') do |f|
      f.write(%{
        class LoadedParticipant
          include Ruote::LocalParticipant
          def initialize (opts)
            @opts = opts
          end
          def consume (workitem)
            workitem.fields['message'] = @opts['message']
            reply(workitem)
          end
        end
      })
    end

    @engine.register_participant(
      :alfred,
      'LoadedParticipant',
      :load_path => path, :message => 'bondzoi')

    assert_equal [ '^alfred$' ], @engine.context.plist.names

    # first run

    assert_equal(
      [ 'LoadedParticipant',
        { 'load_path' => path, 'message' => 'bondzoi' } ],
      @engine.context.plist.lookup_info('alfred', nil))

    wfid = @engine.launch(Ruote.define { alfred })
    r = @engine.wait_for(wfid)

    assert_equal 'bondzoi', r['workitem']['fields']['message']

    # second run

    File.open(path, 'wb') do |f|
      f.write(%{
        class LoadedParticipant
          include Ruote::LocalParticipant
          def initialize (opts)
            @opts = opts
          end
          def consume (workitem)
            workitem.fields['message'] = 'second run'
            reply(workitem)
          end
        end
      })
    end

    wfid = @engine.launch(Ruote.define { alfred })
    r = @engine.wait_for(wfid)

    # since it's a 'load', the code is reloaded

    assert_equal 'second run', r['workitem']['fields']['message']

    FileUtils.rm(path)
  end

  def test_participant_list

    #noisy

    @engine.register_participant 'alpha', Ruote::StorageParticipant

    assert_equal(
      [ '/^alpha$/ ==> Ruote::StorageParticipant {}' ],
      @engine.participant_list.collect { |pe| pe.to_s })

    # launching a process with a missing participant

    wfid = @engine.launch(Ruote.define { bravo })
    @engine.wait_for(wfid)

    assert_equal 1, @engine.process(wfid).errors.size

    # fixing the error by updating the participant list

    list = @engine.participant_list
    list.first.regex = '^.+$' # instead of '^alpha$'
    @engine.participant_list = list

    # replay at error

    @engine.replay_at_error(@engine.process(wfid).errors.first)
    @engine.wait_for(:bravo)

    # bravo should hold a workitem

    assert_equal 1, @engine.storage_participant.size
    assert_equal 'bravo', @engine.storage_participant.first.participant_name
  end

  def test_participant_list_update

    @engine.register_participant 'alpha', Ruote::StorageParticipant

    assert_equal(
      [ '/^alpha$/ ==> Ruote::StorageParticipant {}' ],
      @engine.participant_list.collect { |pe| pe.to_s })

    @engine.participant_list = [
      { 'regex' => '^bravo$',
        'classname' => 'Ruote::StorageParticipant',
        'options' => {} },
      { 'regex' => '^charly$',
        'classname' => 'Ruote::StorageParticipant',
        'options' => {} }
    ]

    assert_equal(
      [
        '/^bravo$/ ==> Ruote::StorageParticipant {}',
        '/^charly$/ ==> Ruote::StorageParticipant {}'
      ],
      @engine.participant_list.collect { |pe| pe.to_s })

    @engine.participant_list = [
      [ '^charly$', [ 'Ruote::StorageParticipant', {} ] ],
      [ '^bravo$', [ 'Ruote::StorageParticipant', {} ] ]
    ]

    assert_equal(
      [
        '/^charly$/ ==> Ruote::StorageParticipant {}',
        '/^bravo$/ ==> Ruote::StorageParticipant {}'
      ],
      @engine.participant_list.collect { |pe| pe.to_s })
  end

  class ParticipantCharlie; end

  def test_register_block

    @engine.register do
      alpha 'Participants::Alpha', 'flavour' => 'vanilla'
      participant 'bravo', 'Participants::Bravo', :flavour => 'peach'
      participant 'charlie', 'Participants::Charlie'
      catchall 'Participants::Zebda', 'flavour' => 'coconut'
    end

    assert_equal 4, @engine.participant_list.size

    assert_equal(
      %w[ ^alpha$ ^bravo$ ^charlie$ ^.+$ ],
      @engine.participant_list.collect { |pe| pe.regex.to_s })

    assert_equal(
      %w[ Participants::Alpha
          Participants::Bravo
          Participants::Charlie
          Participants::Zebda ],
      @engine.participant_list.collect { |pe| pe.classname })

    assert_equal(
      %w[ vanilla peach nil coconut ],
      @engine.participant_list.collect { |pe| pe.options['flavour'] || 'nil' })
  end
end

