
#
# testing ruote
#
# Mon May 18 22:25:57 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote'


class FtParticipantRegistrationTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant_register

    @dashboard.register_participant :alpha do |workitem|
      tracer << 'alpha'
    end
    @dashboard.register_participant /^user_/, Ruote::NullParticipant

    wait_for(2)

    assert_equal(
      'participant_registered',
      logger.log[0]['action'])

    assert_equal(
      %w[ alpha /^user_/ ],
      logger.log.collect { |msg| msg['regex'] })

    assert_equal(
      [ [ '^alpha$',
          [ 'Ruote::BlockParticipant',
            { 'on_workitem' => "proc do |workitem|\n      tracer << 'alpha'\n    end" } ] ],
        [ '^user_',
          [ 'Ruote::NullParticipant',
            {} ] ] ],
      @dashboard.participant_list.collect { |pe| pe.to_a })
  end

  def test_participant_register_position

    @dashboard.register_participant :ur, Ruote::StorageParticipant

    assert_equal(
      %w[ ^ur$ ],
      @dashboard.participant_list.collect { |pe| pe.regex.to_s })

    @dashboard.register_participant(
      :first, Ruote::StorageParticipant, :position => :first)
    @dashboard.register_participant(
      :last, Ruote::StorageParticipant, :position => :last)

    assert_equal(
      %w[ ^first$ ^ur$ ^last$ ],
      @dashboard.participant_list.collect { |pe| pe.regex.to_s })

    @dashboard.register_participant(
      :x, Ruote::StorageParticipant, :position => -2)

    assert_equal(
      %w[ ^first$ ^ur$ ^x$ ^last$ ],
      @dashboard.participant_list.collect { |pe| pe.regex.to_s })
  end

  def test_participant_register_before

    @dashboard.register_participant :alpha, 'AlphaParticipant'
    @dashboard.register_participant :bravo, 'BravoParticipant'
    @dashboard.register_participant :alpha, 'AlphaPrimeParticipant', :pos => :after

    assert_equal(
      [ %w[ ^alpha$ AlphaParticipant ],
        %w[ ^alpha$ AlphaPrimeParticipant ],
        %w[ ^bravo$ BravoParticipant ] ],
      @dashboard.participant_list.collect { |e| [ e.regex, e.classname ] })
  end

  def test_participant_register_after

    @dashboard.register_participant :alpha, 'AlphaParticipant'
    @dashboard.register_participant :alpha, 'AlphaPrimeParticipant', :pos => :before

    assert_equal(
      [ %w[ ^alpha$ AlphaPrimeParticipant ],
        %w[ ^alpha$ AlphaParticipant ] ],
      @dashboard.participant_list.collect { |e| [ e.regex, e.classname ] })
  end

  def test_participant_register_before_after_corner_cases

    @dashboard.register_participant :alpha, 'KlassA', :pos => :before
    @dashboard.register_participant :bravo, 'KlassB', :pos => :after

    assert_equal(
      [ %w[ ^alpha$ KlassA ],
        %w[ ^bravo$ KlassB ] ],
      @dashboard.participant_list.collect { |e| [ e.regex, e.classname ] })
  end

  def test_participant_register_over

    @dashboard.register_participant :alpha, 'KlassA'
    @dashboard.register_participant :bravo, 'KlassB'
    @dashboard.register_participant :alpha, 'KlassAa', :pos => :over
    @dashboard.register_participant :charly, 'KlassC', :pos => :over

    assert_equal(
      [ %w[ ^alpha$ KlassAa ],
        %w[ ^bravo$ KlassB ],
        %w[ ^charly$ KlassC ] ],
      @dashboard.participant_list.collect { |e| [ e.regex, e.classname ] })
  end

  def test_double_registration

    @dashboard.register_participant :alpha do |workitem|
      tracer << 'alpha'
    end
    @dashboard.register_participant :alpha do |workitem|
      tracer << 'alpha'
    end

    assert_equal 1, @dashboard.context.plist.send(:get_list)['list'].size
  end

  def test_register_and_return_something

    pa = @dashboard.register_participant :alpha do |workitem|
    end
    pb = @dashboard.register_participant :bravo, Ruote::StorageParticipant

    assert_nil pa
    assert_equal Ruote::StorageParticipant, pb.class
  end

  def test_participant_unregister_by_name

    @dashboard.register_participant :alpha do |workitem|
    end

    @dashboard.unregister_participant(:alpha)

    wait_for(2)
    Thread.pass

    msg = logger.log.last
    assert_equal 'participant_unregistered', msg['action']
    assert_equal '^alpha$', msg['regex']
  end

  def test_participant_unregister

    @dashboard.register_participant :alpha do |workitem|
    end

    @dashboard.unregister_participant('alpha')

    wait_for(2)

    msg = logger.log.last
    assert_equal 'participant_unregistered', msg['action']
    assert_equal '^alpha$', msg['regex']

    assert_equal 0, @dashboard.context.plist.list.size
  end

  class MyParticipant
    @@down = false
    def self.down
      @@down
    end
    def initialize
    end
    def shutdown
      @@down = true
    end
  end

  def test_participant_shutdown

    alpha = @dashboard.register :alpha, MyParticipant

    @dashboard.context.plist.shutdown

    assert_equal true, MyParticipant.down
  end

  def test_participant_list_of_names

    pa = @dashboard.register_participant :alpha do |workitem|
    end

    assert_equal [ '^alpha$' ], @dashboard.context.plist.names
  end

  def test_register_require_path

    rpath = File.expand_path(
      "../#{Time.now.to_f}_#{$$}_required_participant", __FILE__)
    path = "#{rpath}.rb"

    File.open(path, 'wb') do |f|
      f.write(%{
        class RequiredParticipant
          include Ruote::LocalParticipant
          def initialize(opts)
            @opts = opts
          end
          def consume(workitem)
            workitem.fields['message'] = @opts['message']
            reply(workitem)
          end
        end
      })
    end

    @dashboard.register_participant(
      :alfred,
      'RequiredParticipant',
      :require_path => rpath, :message => 'hello')

    assert_equal [ '^alfred$' ], @dashboard.context.plist.names

    # first run

    assert_equal(
      [ 'RequiredParticipant',
        { 'require_path' => rpath, 'message' => 'hello' } ],
      @dashboard.context.plist.lookup_info('alfred', nil))

    wfid = @dashboard.launch(Ruote.define { alfred })
    r = @dashboard.wait_for(wfid)

    assert_equal 'hello', r['workitem']['fields']['message']

    # second run

    File.open(path, 'wb') do |f|
      f.write(%{
        class RequiredParticipant
          include Ruote::LocalParticipant
          def initialize(opts)
            @opts = opts
          end
          def consume(workitem)
            workitem.fields['message'] = 'second run'
            reply(workitem)
          end
        end
      })
    end

    wfid = @dashboard.launch(Ruote.define { alfred })
    r = @dashboard.wait_for(wfid)

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
          def initialize(opts)
            @opts = opts
          end
          def consume(workitem)
            workitem.fields['message'] = @opts['message']
            reply(workitem)
          end
        end
      })
    end

    @dashboard.register_participant(
      :alfred,
      'LoadedParticipant',
      :load_path => path, :message => 'bondzoi')

    assert_equal [ '^alfred$' ], @dashboard.context.plist.names

    # first run

    assert_equal(
      [ 'LoadedParticipant',
        { 'load_path' => path, 'message' => 'bondzoi' } ],
      @dashboard.context.plist.lookup_info('alfred', nil))

    wfid = @dashboard.launch(Ruote.define { alfred })
    r = @dashboard.wait_for(wfid)

    assert_equal 'bondzoi', r['workitem']['fields']['message']

    # second run

    File.open(path, 'wb') do |f|
      f.write(%{
        class LoadedParticipant
          include Ruote::LocalParticipant
          def initialize(opts)
            @opts = opts
          end
          def consume(workitem)
            workitem.fields['message'] = 'second run'
            reply(workitem)
          end
        end
      })
    end

    wfid = @dashboard.launch(Ruote.define { alfred })
    r = @dashboard.wait_for(wfid)

    # since it's a 'load', the code is reloaded

    assert_equal 'second run', r['workitem']['fields']['message']

    FileUtils.rm(path)
  end

  def test_participant_list

    @dashboard.register_participant 'alpha', Ruote::StorageParticipant

    #assert_equal(
    #  [ '/^alpha$/ ==> Ruote::StorageParticipant {}' ],
    #  @dashboard.participant_list.collect { |pe| pe.to_s })

    plist = @dashboard.participant_list

    assert_equal 1, plist.size
    assert_equal '^alpha$', plist.first.regex
    assert_equal 'Ruote::StorageParticipant', plist.first.classname

    # launching a process with a missing participant

    wfid = @dashboard.launch(Ruote.define { bravo })
    @dashboard.wait_for(wfid)

    assert_equal 1, @dashboard.process(wfid).errors.size

    # fixing the error by updating the participant list

    list = @dashboard.participant_list
    list.first.regex = '^.+$' # instead of '^alpha$'
    @dashboard.participant_list = list

    # replay at error

    @dashboard.replay_at_error(@dashboard.process(wfid).errors.first)
    @dashboard.wait_for(:bravo)

    # bravo should hold a workitem

    assert_equal 1, @dashboard.storage_participant.size
    assert_equal 'bravo', @dashboard.storage_participant.first.participant_name
  end

  def test_participant_list_update

    @dashboard.register_participant 'alpha', Ruote::StorageParticipant

    #assert_equal(
    #  [ '/^alpha$/ ==> Ruote::StorageParticipant {}' ],
    #  @dashboard.participant_list.collect { |pe| pe.to_s })

    plist = @dashboard.participant_list

    assert_equal 1, plist.size
    assert_equal '^alpha$', plist.first.regex
    assert_equal 'Ruote::StorageParticipant', plist.first.classname

    # 0

    @dashboard.participant_list = [
      { 'regex' => '^bravo$',
        'classname' => 'Ruote::StorageParticipant',
        'options' => {} },
      { 'regex' => '^charly$',
        'classname' => 'Ruote::StorageParticipant',
        'options' => {} }
    ]

    #assert_equal(
    #  [
    #    '/^bravo$/ ==> Ruote::StorageParticipant {}',
    #    '/^charly$/ ==> Ruote::StorageParticipant {}'
    #  ],
    #  @dashboard.participant_list.collect { |pe| pe.to_s })

    plist = @dashboard.participant_list

    assert_equal 2, plist.size
    assert_equal '^bravo$', plist.first.regex
    assert_equal '^charly$', plist.last.regex
    assert_equal 'Ruote::StorageParticipant', plist.first.classname
    assert_equal 'Ruote::StorageParticipant', plist.last.classname

    # 1

    @dashboard.participant_list = [
      [ '^charly$', [ 'Ruote::StorageParticipant', {} ] ],
      [ '^bravo$', [ 'Ruote::StorageParticipant', {} ] ]
    ]

    plist = @dashboard.participant_list

    assert_equal 2, plist.size
    assert_equal '^charly$', plist.first.regex
    assert_equal '^bravo$', plist.last.regex
    assert_equal 'Ruote::StorageParticipant', plist.first.classname
    assert_equal 'Ruote::StorageParticipant', plist.last.classname

    # 2

    @dashboard.participant_list = [
      [ '^delta$', Ruote::StorageParticipant, {} ],
      [ '^echo$', 'Ruote::StorageParticipant', {} ]
    ]

    plist = @dashboard.participant_list

    assert_equal 2, plist.size
    assert_equal '^delta$', plist.first.regex
    assert_equal '^echo$', plist.last.regex
    assert_equal 'Ruote::StorageParticipant', plist.first.classname
    assert_equal 'Ruote::StorageParticipant', plist.last.classname
  end

  class ParticipantCharlie; end

  def test_register_block

    @dashboard.register do
      alpha 'Participants::Alpha', 'flavour' => 'vanilla'
      participant 'bravo', 'Participants::Bravo', :flavour => 'peach'
      participant 'charlie', 'Participants::Charlie'
      participant 'david' do |wi|
        p wi
      end
      catchall 'Participants::Zebda', 'flavour' => 'coconut'
    end

    assert_equal 5, @dashboard.participant_list.size

    assert_equal(
      %w[ ^alpha$ ^bravo$ ^charlie$ ^david$ ^.+$ ],
      @dashboard.participant_list.collect { |pe| pe.regex.to_s })

    assert_equal(
      %w[ Participants::Alpha
          Participants::Bravo
          Participants::Charlie
          Ruote::BlockParticipant
          Participants::Zebda ],
      @dashboard.participant_list.collect { |pe| pe.classname })

    assert_equal(
      %w[ vanilla peach nil nil coconut ],
      @dashboard.participant_list.collect { |pe|
        (pe.options['flavour'] || 'nil') rescue 'nil'
      })
  end

  def test_register_block_and_block

    @dashboard.register do
      alpha do |workitem|
        a
      end
      participant 'bravo' do |workitem|
        b
      end
    end

    assert_equal(
      [ [ 'on_workitem' ], [ 'on_workitem' ] ],
      @dashboard.participant_list.collect { |pe| pe.options.keys })
  end

  def test_register_block_catchall_default

    @dashboard.register do
      catchall
    end

    assert_equal(
      %w[ Ruote::StorageParticipant ],
      @dashboard.participant_list.collect { |pe| pe.classname })
  end

  def test_register_block_catch_all

    @dashboard.register do
      catch_all
    end

    assert_equal(
      %w[ Ruote::StorageParticipant ],
      @dashboard.participant_list.collect { |pe| pe.classname })
  end

  def test_register_block_override_false

    @dashboard.register do
      alpha 'KlassA'
      alpha 'KlassB'
    end

    plist = @dashboard.participant_list

    assert_equal(%w[ ^alpha$ ^alpha$ ], plist.collect { |pe| pe.regex })
    assert_equal(%w[ KlassA KlassB ], plist.collect { |pe| pe.classname })
    assert_equal({}, plist.first.options)
  end

  def test_register_block_clears

    @dashboard.register 'alpha', 'AlphaParticipant'

    @dashboard.register do
      bravo 'BravoParticipant'
    end

    assert_equal 1, @dashboard.participant_list.size
  end

  def test_register_block_clear_option

    @dashboard.register 'alpha', 'AlphaParticipant'

    @dashboard.register :clear => false do
      bravo 'BravoParticipant'
    end

    assert_equal 2, @dashboard.participant_list.size
  end

  def test_argument_error_on_instantiated_participant

    assert_raise ArgumentError do
      @dashboard.register 'alpha', Ruote::StorageParticipant.new
    end
    assert_raise ArgumentError do
      @dashboard.register 'alpha', Ruote::StorageParticipant.new, 'hello' => 'kitty'
    end
  end

  class AaParticipant
    include Ruote::LocalParticipant
    attr_reader :opts
    def initialize(opts)
      @opts = opts
    end
  end
  class BbParticipant < AaParticipant
    def accept?(workitem)
      false
    end
  end

  def test_engine_participant

    @dashboard.register do
      alpha AaParticipant
      bravo BbParticipant
      catchall AaParticipant, :catch_all => 'oh yeah'
    end

    assert_equal AaParticipant, @dashboard.participant('alpha').class
    assert_equal BbParticipant, @dashboard.participant('bravo').class

    assert_equal AaParticipant, @dashboard.participant('charly').class
    assert_equal 'oh yeah', @dashboard.participant('charly').opts['catch_all']

    assert_equal Ruote::Context, @dashboard.participant('alpha').context.class
  end
end

