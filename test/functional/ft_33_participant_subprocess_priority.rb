
#
# testing ruote
#
# Wed Oct 21 05:35:29 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtParticipantSubprocessPriorityTest < Test::Unit::TestCase
  include FunctionalBase

  def test_priority

    pdef = Ruote.process_definition do
      sub0
      define 'sub0' do
        echo 'sub0'
      end
    end

    @engine.register_participant '.+' do
      @tracer << 'participant'
    end

    #noisy

    assert_trace 'sub0', pdef
  end
end

