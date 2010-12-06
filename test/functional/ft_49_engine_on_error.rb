
#
# testing ruote
#
# Mon Dec  6 10:02:56 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class FtEngineOnErrorTest < Test::Unit::TestCase
  include FunctionalBase

  def setup
    super
    $seen = []
  end

  def test_on_error

    @engine.on_error = 'supervisor'

    assert_equal(
      { 'on_error' => [ 'supervisor' ] },
      @engine.notifications)

    assert_equal(
      [ 'supervisor' ],
      @engine.on_error)
  end

  class Supervisor
    include Ruote::LocalParticipant
    def initialize (opts)
      @opts = opts
    end
    def consume (workitem)
      workitem.fields['flavour'] = @opts['flavour']
      $seen << workitem
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

    assert_equal 1, $seen.size
    assert_equal 'yellow', $seen.first.fields['colour']
    assert_equal 'vanilla', $seen.first.fields['flavour']
    assert_not_nil $seen.first.fei.sub_wfid

    # TODO : look for error message and such

    @engine.wait_for($seen.first.wfid)

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

  #def test_on_error_class
  #  flunk
  #end
end

