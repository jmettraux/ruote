
#
# testing ruote
#
# Wed Jun 29 12:05:41 JST 2011
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/workitem'
require 'ruote/part/local_participant'


class UtParticipantsTest < Test::Unit::TestCase

  class OldParticipant
    include Ruote::LocalParticipant
    def consume(workitem)
      $result = workitem.fields['test']
    end
  end

  class NewParticipant
    include Ruote::LocalParticipant
    def on_workitem
      $result = workitem.fields['test']
    end
  end

  def new_workitem(fields)
    Ruote::Workitem.new('fields' => fields)
  end

  def test_consume

    OldParticipant.new._consume(new_workitem('test' => 'zero'))
    assert_equal 'zero', $result
    OldParticipant.new._on_workitem(new_workitem('test' => 'zero'))
    assert_equal 'zero', $result

    NewParticipant.new._consume(new_workitem('test' => 'one'))
    assert_equal 'one', $result
    NewParticipant.new._on_workitem(new_workitem('test' => 'one'))
    assert_equal 'one', $result
  end
end

