
#
# testing ruote
#
# Thu Jan  6 21:49:01 JST 2011
#

require File.expand_path('../base', __FILE__)

#require 'ruote/participant'


class FtEngineOnTerminateTest < Test::Unit::TestCase
  include FunctionalBase

  def test_no_on_terminate

    assert_nil @engine.on_terminate
  end

  def test_on_terminate

    @engine.on_terminate = 'supervisor'

    assert_equal(
      [ 'define', {}, [ [ 'supervisor', {}, [] ] ] ],
      @engine.on_terminate)
  end

  def test_on_terminate_tree

    @engine.on_terminate = Ruote.define do
      echo '${__terminate__.wfid} terminated'
    end

    #@engine.noisy = true

    wfid = @engine.launch(Ruote.define do
      echo 'main'
    end)

    @engine.wait_for(wfid)
    sleep 1

    assert_equal [ 'main', "#{wfid} terminated" ], @tracer.to_a
  end

  # on_terminate processes are not triggered for on_error processes.
  #
  def test_no_on_terminate_when_on_error

    @engine.on_error = Ruote.define do
      echo 'on_error'
    end
    @engine.on_terminate = Ruote.define do
      echo 'on_terminate'
    end

    #noisy

    wfid = @engine.launch(Ruote.define do
      echo 'main'
      error 'in main'
    end)

    @engine.wait_for(wfid)
    sleep 1

    assert_equal [ 'main', 'on_error' ], @tracer.to_a
  end

  # on_error processes are triggered for on_terminate processes as well.
  #
  def test_on_error_when_on_terminate

    @engine.on_error = Ruote.define do
      echo 'on_error'
    end
    @engine.on_terminate = Ruote.define do
      error 'in on_terminate'
    end

    #noisy

    wfid = @engine.launch(Ruote.define do
      echo 'main'
    end)

    @engine.wait_for(wfid)
    sleep 1

    assert_equal [ 'main', 'on_error' ], @tracer.to_a
  end
end

