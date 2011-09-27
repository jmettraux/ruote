
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

    assert_nil @dashboard.on_terminate
  end

  def test_on_terminate

    @dashboard.on_terminate = 'supervisor'

    assert_equal(
      [ 'define', {}, [ [ 'supervisor', {}, [] ] ] ],
      @dashboard.on_terminate)
  end

  def test_on_terminate_tree

    @dashboard.on_terminate = Ruote.define do
      echo '${__terminate__.wfid} terminated'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      echo 'main'
    end)

    @dashboard.wait_for(8)

    assert_equal [ 'main', "#{wfid} terminated" ], @tracer.to_a
  end

  # on_terminate processes are not triggered for on_error processes.
  #
  def test_no_on_terminate_when_on_error

    @dashboard.on_error = Ruote.define do
      echo 'on_error'
    end
    @dashboard.on_terminate = Ruote.define do
      echo 'on_terminate'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      echo 'main'
      error 'in main'
    end)

    @dashboard.wait_for(9)

    assert_equal [ 'main', 'on_error' ], @tracer.to_a
  end

  # on_error processes are triggered for on_terminate processes as well.
  #
  def test_on_error_when_on_terminate

    @dashboard.on_error = Ruote.define do
      echo 'on_error'
    end
    @dashboard.on_terminate = Ruote.define do
      error 'in on_terminate'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      echo 'main'
    end)

    @dashboard.wait_for(11)

    assert_equal [ 'main', 'on_error' ], @tracer.to_a
  end
end

