
#
# testing ruote
#
# Mon Dec  6 10:02:56 JST 2010
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtEngineOnErrorTest < Test::Unit::TestCase
  include FunctionalBase

  def setup
    super
    @engine.context.stash[:seen] = []
  end

  def test_no_on_error

    assert_nil @engine.on_error
  end

  def test_on_error

    @engine.on_error = 'supervisor'

    assert_equal(
      [ 'define', {}, [ [ 'supervisor', {}, [] ] ] ],
      @engine.on_error)
  end

  class Supervisor
    include Ruote::LocalParticipant
    def initialize(opts)
      @opts = opts
    end
    def consume(workitem)
      workitem.fields['flavour'] = @opts['flavour']
      @context.stash[:seen] << workitem
      reply(workitem)
    end
  end

  WRONGY = Ruote.process_definition do
    error "something went wrong"
  end

  def test_on_error_participant

    @engine.register 'supervisor', Supervisor, 'flavour' => 'vanilla'
    @engine.on_error = 'supervisor'

    #@engine.noisy = true

    wfid = @engine.launch(WRONGY, 'colour' => 'yellow')

    @engine.wait_for(wfid)
    @engine.wait_for(:supervisor)

    sleep 0.350
      # unfortunately waiting for a participant triggers right
      # before the consume

    assert_equal 1, @engine.context.stash[:seen].size
    assert_equal 'yellow', @engine.context.stash[:seen].first.fields['colour']
    assert_equal 'vanilla', @engine.context.stash[:seen].first.fields['flavour']
    assert_not_nil @engine.context.stash[:seen].first.fei.subid

    # TODO : look for error message and such

    @engine.wait_for(@engine.context.stash[:seen].first.wfid)

    assert_equal 1, @engine.processes.size
  end

  def test_on_error_engine_subprocess_name

    @engine.variables['trigger_alarm'] = Ruote.define do
      echo '${colour} seen'
    end
    @engine.on_error = 'trigger_alarm'

    #@engine.noisy = true

    wfid = @engine.launch(WRONGY, 'colour' => 'red')

    @engine.wait_for(wfid)

    sleep 0.700
      # letting the subprocess getting triggered

    assert_equal 'red seen', @tracer.to_s
    assert_equal 1, @engine.processes.size
  end

  def test_on_error_local_subprocess_name

    @engine.variables['trigger_alarm'] = Ruote.define do
      echo '${colour} seen'
    end
    @engine.on_error = 'trigger_alarm'

    pdef = Ruote.define do
      error 'still wrong'
      define 'trigger_alarm' do
        echo 'saw ${colour}'
      end
    end

    wfid = @engine.launch(pdef, 'colour' => 'green')

    @engine.wait_for(wfid)

    sleep 0.700
      # letting the subprocess getting triggered

    assert_equal 'saw green', @tracer.to_s
    assert_equal 1, @engine.processes.size
  end

  def test_on_error_subprocess_tree

    @engine.on_error = Ruote.define do
      echo 'case ${colour}'
    end

    wfid = @engine.launch(WRONGY, 'colour' => 'blue')

    @engine.wait_for(wfid)

    sleep 0.700
      # letting the subprocess getting triggered

    assert_equal 'case blue', @tracer.to_s
    assert_equal 1, @engine.processes.size
  end

  def test_on_error_workitem

    @engine.register 'supervisor', Supervisor
    @engine.on_error = 'supervisor'

    #@engine.noisy = true

    wfid = @engine.launch(WRONGY, 'colour' => 'crimson')

    @engine.wait_for(wfid)
    @engine.wait_for(:supervisor)

    sleep 0.350
      # unfortunately waiting for a participant triggers right
      # before the consume

    wi = @engine.context.stash[:seen].first

    assert_not_nil wi.error
  end

  def test_cascade_prevention

    @engine.on_error = Ruote.define { error "nada" }

    #@engine.noisy = true

    wfid = @engine.launch(WRONGY, 'colour' => 'purple')

    @engine.wait_for(wfid)
    @engine.wait_for(wfid)

    sleep 0.700
      # give it a bit of time, to make sure no supplementary errors crop up

    assert_equal 2, @engine.process(wfid).errors.size
  end

  def test_doesnt_trigger_for_checked_error

    pdef = Ruote.define do
      nemo :on_error => 'pass'
    end

    @engine.on_error = Ruote.define do
      echo 'seen'
    end

    wfid = @engine.launch(pdef)

    #noisy

    @engine.wait_for(wfid)

    sleep 0.700
      # give it a bit of time, to make sure no supplementary errors crop up

    assert_equal '', @tracer.to_s
  end
end

