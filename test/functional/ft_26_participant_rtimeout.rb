
#
# testing ruote
#
# Sun Aug 16 14:25:35 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtParticipantTimeoutTest < Test::Unit::TestCase
  include FunctionalBase

  class AlphaParticipant < Ruote::StorageParticipant
    def rtimeout(workitem)
      '1s'
    end
  end

  def test_participant_defined_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha
        bravo
      end
    end

    @engine.register_participant :alpha, AlphaParticipant
    sto = @engine.register_participant :bravo, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(13)

    assert_equal 1, sto.size
    assert_equal 'bravo', sto.first.participant_name

    #logger.log.each { |l| p l }
    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
    assert_equal 0, @engine.storage.get_many('schedules').size

    assert_not_nil sto.first.fields['__timed_out__']
  end

  class MyParticipant
    include Ruote::LocalParticipant
    def consume(workitem)
      # do nothing
    end
    def cancel(fei, flavour)
      # do nothing
    end
    def rtimeout
      '1s'
    end
    def do_not_thread
      true
    end
  end

  def test_participant_class_defined_timeout

    pdef = Ruote.define do
      alpha
      echo 'done.'
    end

    @engine.register_participant :alpha, MyParticipant

    #noisy

    wfid = @engine.launch(pdef)

    @engine.wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
  end

  def test_pdef_overriden_timeout

    # process definition cancels timeout given by participant

    #@engine.noisy = true

    pdef = Ruote.define do
      alpha :timeout => ''
      echo 'done.'
    end

    @engine.register_participant :alpha, MyParticipant

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    sleep 0.350

    assert_equal 0, @engine.storage.get_many('schedules').size
    assert_equal '', @tracer.to_s
  end

  class MyOtherParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
      @opts = opts
    end
    def consume(workitem)
      # do nothing
    end
    def cancel(fei, flavour)
      # do nothing
    end
    def rtimeout(workitem)
      @opts['timeout']
    end
  end

  def test_participant_option_defined_timeout

    pdef = Ruote.define do
      alpha
      bravo
      echo 'done.'
    end

    @engine.register_participant :alpha, MyOtherParticipant, 'timeout' => '1s'
    @engine.register_participant :bravo, MyOtherParticipant

    #noisy

    wfid = @engine.launch(pdef)

    @engine.wait_for(:bravo)

    assert_equal 0, @engine.storage.get_many('schedules').size
      # no timeout for participant :bravo
  end

  class YetAnotherParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
      @opts = opts
    end
    def consume(workitem)
      # do nothing
    end
    def cancel(fei, flavour)
      # do nothing
    end
    def rtimeout(workitem)
      "#{workitem.fields['timeout'] * 2}s"
    end
  end

  def test_participant_rtimeout_workitem

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha, YetAnotherParticipant

    #noisy

    wfid = @engine.launch(pdef, 'timeout' => 60)

    @engine.wait_for(:alpha)
    @engine.wait_for(1)

    schedules = @engine.storage.get_many('schedules')

    assert_equal 1, schedules.size
    assert_equal '120s', schedules.first['original']
  end
end

