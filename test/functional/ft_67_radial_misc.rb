
#
# testing ruote
#
# Thu Sep  1 02:03:39 JST 2011
#
# Santa Barbara
#

require File.expand_path('../base', __FILE__)


class FtRadialMiscTest < Test::Unit::TestCase
  include FunctionalBase

  def test_dollar

    pdef = %{
      define
        set "f:a": toto
        echo "$f:a"
    }

    @engine.register_participant '.+', Ruote::NullParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal 'toto', @tracer.to_s
  end
end

