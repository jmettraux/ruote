
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

  def test_on_error

    pdef = Ruote.process_definition do
      on_error 'catcher'
      nada
    end

    @dashboard.register_participant :catcher do
      @tracer << "caught\n"
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
      @tracer << workitem.participant_name
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
      @tracer << workitem.participant_name
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'bravo', @tracer.to_s
  end
end

