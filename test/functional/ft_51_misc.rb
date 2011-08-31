
#
# testing ruote
#
# Thu Dec  9 16:39:54 JST 2010
#

require 'stringio'
require File.expand_path('../base', __FILE__)


class FtMiscTest < Test::Unit::TestCase
  include FunctionalBase

  def test_noisy

    result = String.new
    out = StringIO.new(result, 'w+')

    prev = $stdout
    $stdout = out

    @engine.noisy = true

    wfid = @engine.launch(Ruote.define do
      echo 'nada'
    end)

    @engine.wait_for(wfid)

    out.close
    $stdout = prev

    assert_not_nil result
  end

  class NoCancel
    def consume(workitem)
      # do nothing
    end
    # no cancel method implementation
  end

  def test_participant_missing_cancel_method

    pdef = Ruote.define do
      participant 'no_cancel'
    end

    @engine.register 'no_cancel', NoCancel

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:no_cancel)

    @engine.cancel(wfid)

    @engine.wait_for(wfid)

    assert_match(
      /undefined method `on_cancel' for/,
      @engine.ps(wfid).errors.first.message)
  end
end

