
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

    @dashboard.register_participant :alpha, AlphaParticipant
    sto = @dashboard.register_participant :bravo, Ruote::StorageParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('dispatched')
    @dashboard.wait_for('dispatched')

    assert_equal 1, sto.size
    assert_equal 'bravo', sto.first.participant_name

    #logger.log.each { |l| p l }
    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
    assert_equal 0, @dashboard.storage.get_many('schedules').size

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

    @dashboard.register_participant :alpha, MyParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
  end

  def test_pdef_overriden_timeout

    # process definition cancels timeout given by participant

    #@dashboard.noisy = true

    pdef = Ruote.define do
      alpha :timeout => ''
      echo 'done.'
    end

    @dashboard.register_participant :alpha, MyParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('dispatched')

    assert_equal 0, @dashboard.storage.get_many('schedules').size
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

    @dashboard.register_participant :alpha, MyOtherParticipant, 'timeout' => '1s'
    @dashboard.register_participant :bravo, MyOtherParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:bravo)

    assert_equal 0, @dashboard.storage.get_many('schedules').size
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

    @dashboard.register_participant :alpha, YetAnotherParticipant

    #noisy

    wfid = @dashboard.launch(pdef, 'timeout' => 60)

    @dashboard.wait_for(:alpha)
    @dashboard.wait_for(1)

    schedules = @dashboard.storage.get_many('schedules')

    assert_equal 1, schedules.size
    assert_equal '120s', schedules.first['original']

    ps = @dashboard.ps(wfid)

    assert_not_nil ps.expressions.last.h.timers
    assert_equal 1, ps.expressions.last.h.timers.size
    assert_equal 'timeout', ps.expressions.last.h.timers.first.last
  end
end

