
#
# Testing Ruote (OpenWFEru)
#
# Fri May 15 09:51:28 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtProcessStatusTest < Test::Unit::TestCase
  include FunctionalBase

  def test_error

    pdef = Ruote.process_definition do
      nada
    end

    #noisy

    wfid = @engine.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait

    ps = @engine.process_status(wfid)

    assert_equal 1, ps.errors.size
  end
end

