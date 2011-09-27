
#
# testing ruote
#
# Mon Sep 14 19:11:45 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/part/no_op_participant'
require 'ruote/part/null_participant'


class FtNullNoopParticipantsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_null_participant

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    alpha = @dashboard.register_participant :alpha, Ruote::NullParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(4)

    ps = @dashboard.process(wfid)

    assert_not_nil ps
    assert_equal [], ps.errors
  end

  def test_noop_participant

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
      echo 'done.'
    end

    @dashboard.register_participant :alpha, Ruote::NoOpParticipant

    #noisy

    assert_trace "done.", pdef
  end
end

