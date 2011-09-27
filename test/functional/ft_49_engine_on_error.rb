
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
    @dashboard.context.stash[:seen] = []
  end

  def test_no_on_error

    assert_nil @dashboard.on_error
  end

  def test_on_error

    @dashboard.on_error = 'supervisor'

    assert_equal(
      [ 'define', {}, [ [ 'supervisor', {}, [] ] ] ],
      @dashboard.on_error)
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

    @dashboard.register 'supervisor', Supervisor, 'flavour' => 'vanilla'
    @dashboard.on_error = 'supervisor'

    #@dashboard.noisy = true

    wfid = @dashboard.launch(WRONGY, 'colour' => 'yellow')

    @dashboard.wait_for(wfid)
    @dashboard.wait_for(:supervisor)
    @dashboard.wait_for(1)

    assert_equal 1, @dashboard.context.stash[:seen].size
    assert_equal 'yellow', @dashboard.context.stash[:seen].first.fields['colour']
    assert_equal 'vanilla', @dashboard.context.stash[:seen].first.fields['flavour']
    assert_not_nil @dashboard.context.stash[:seen].first.fei.subid

    # TODO : look for error message and such

    @dashboard.wait_for(@dashboard.context.stash[:seen].first.wfid)

    assert_equal 1, @dashboard.processes.size
  end

  def test_on_error_engine_subprocess_name

    @dashboard.variables['trigger_alarm'] = Ruote.define do
      echo '${colour} seen'
    end
    @dashboard.on_error = 'trigger_alarm'

    #@dashboard.noisy = true

    wfid = @dashboard.launch(WRONGY, 'colour' => 'red')

    @dashboard.wait_for(11)

    assert_equal 'red seen', @tracer.to_s
    assert_equal 1, @dashboard.processes.size
  end

  def test_on_error_local_subprocess_name

    @dashboard.variables['trigger_alarm'] = Ruote.define do
      echo '${colour} seen'
    end
    @dashboard.on_error = 'trigger_alarm'

    #@dashboard.noisy = true

    pdef = Ruote.define do
      error 'still wrong'
      define 'trigger_alarm' do
        echo 'saw ${colour}'
      end
    end

    wfid = @dashboard.launch(pdef, 'colour' => 'green')

    @dashboard.wait_for(14)

    assert_equal 'saw green', @tracer.to_s
    assert_equal 1, @dashboard.processes.size
  end

  def test_on_error_subprocess_tree

    @dashboard.on_error = Ruote.define do
      echo 'case ${colour}'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(WRONGY, 'colour' => 'blue')

    @dashboard.wait_for(7)

    assert_equal 'case blue', @tracer.to_s
    assert_equal 1, @dashboard.processes.size
  end

  def test_on_error_workitem

    @dashboard.register 'supervisor', Supervisor
    @dashboard.on_error = 'supervisor'

    #@dashboard.noisy = true

    wfid = @dashboard.launch(WRONGY, 'colour' => 'crimson')

    @dashboard.wait_for(wfid)
    @dashboard.wait_for(:supervisor)
    @dashboard.wait_for(1)

    wi = @dashboard.context.stash[:seen].first

    assert_not_nil wi.error
  end

  def test_cascade_prevention

    @dashboard.on_error = Ruote.define { error "nada" }

    #@dashboard.noisy = true

    wfid = @dashboard.launch(WRONGY, 'colour' => 'purple')

    @dashboard.wait_for(6)

    assert_equal 2, @dashboard.process(wfid).errors.size
  end

  def test_doesnt_trigger_for_checked_error

    pdef = Ruote.define do
      nemo :on_error => 'pass'
    end

    @dashboard.on_error = Ruote.define do
      echo 'seen'
    end

    wfid = @dashboard.launch(pdef)

    #@dashboard.noisy = true

    @dashboard.wait_for(wfid)
    sleep 2.0
      # give it a bit of time, to make sure no supplementary errors crop up

    assert_equal '', @tracer.to_s
  end
end

