
#
# testing ruote
#
# Tue Jul 19 18:05:49 JST 2011
#
# Hiroshima
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftOnErrorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_on_error

    pdef = Ruote.process_definition do
      on_error
      echo 'over.'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal 'over.', @tracer.to_s
  end

  def test_on_error

    pdef = Ruote.process_definition do
      on_error 'catcher'
      nada
    end

    @dashboard.register_participant :catcher do
      tracer << "caught\n"
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'caught', @tracer.to_s
    assert_equal 1, logger.log.select { |e| e['action'] == 'fail' }.size
  end

  def test_on_error_regex

    pdef = Ruote.process_definition do
      on_error /unknown participant/ => 'bravo'
      on_error 'alpha'
      nada
    end

    @dashboard.register_participant /alpha|bravo/ do |workitem|
      tracer << workitem.participant_name
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'bravo', @tracer.to_s
  end

  def test_on_error_block

    pdef = Ruote.process_definition do
      on_error do
        echo 'caught'
      end
      nada
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'caught', @tracer.to_s
  end

  def test_on_error_block_and_regex

    pdef = Ruote.process_definition do
      on_error /unknown participant/ do
        echo 'unknown participant'
      end
      on_error do
        echo 'caught'
      end
      nada
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'unknown participant', @tracer.to_s
  end

  def test_class_match

    pdef = Ruote.process_definition do
      on_error 'RuntimeError' => 'bravo'
      on_error 'alpha'
      nada
    end

    @dashboard.register_participant /alpha|bravo/ do |workitem|
      tracer << workitem.participant_name
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'bravo', @tracer.to_s
  end

  class BadParticipant
    include Ruote::LocalParticipant
    def on_workitem
      fail '503 retry later'
    end
    def on_cancel
      # nada
    end
  end

  def test_enhanced_retry

    @dashboard.register :toto, BadParticipant

    pdef = Ruote.define do
      sequence do
        on_error /503/ => '1s: retry'
        participant 'toto'
      end
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('dispatch_cancel')
    @dashboard.wait_for(2)

    assert_equal 1, @dashboard.ps(wfid).expressions.last.h.timers.size

    @dashboard.wait_for('error_intercepted')

    assert_equal(
      '#<RuntimeError: 503 retry later>',
      @dashboard.ps(wfid).errors.first.message)
  end

  def test_enhanced_retry_no_pattern

    @dashboard.register :toto, BadParticipant

    pdef = Ruote.define do
      sequence do
        on_error '1s: retry'
        participant 'toto'
      end
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('dispatch_cancel')
    @dashboard.wait_for(2)

    assert_equal 1, @dashboard.ps(wfid).expressions.last.h.timers.size

    @dashboard.wait_for('error_intercepted')

    assert_equal(
      '#<RuntimeError: 503 retry later>',
      @dashboard.ps(wfid).errors.first.message)
  end
end

