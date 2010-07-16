
#
# testing ruote
#
# Sun Aug 16 14:25:35 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class FtParticipantTimeoutTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant_defined_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant.new

    class << alpha
      def timeout
        '1s'
      end
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(13)

    assert_equal 0, alpha.size
    assert_equal 1, bravo.size

    #logger.log.each { |l| p l }
    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
    assert_equal 0, @engine.storage.get_many('schedules').size

    assert_not_nil bravo.first.fields['__timed_out__']
  end

  class MyParticipant
    include Ruote::LocalParticipant
    def consume (workitem)
      # do nothing
    end
    def cancel (fei, flavour)
      # do nothing
    end
    def timeout
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
    def initialize (opts)
      @opts = opts
    end
    def consume (workitem)
      # do nothing
    end
    def cancel (fei, flavour)
      # do nothing
    end
    def timeout
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
end

