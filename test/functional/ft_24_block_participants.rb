
#
# Testing Ruote (OpenWFEru)
#
# Tue Aug 11 13:56:28 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtBlockParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitems_dispatching_message

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'v0', :val => 'v0val'
        set :field => 'f0', :val => 'f0val'
        alpha
        bravo
        charly
      end
    end

    @engine.register_participant :alpha do
      @tracer << "a\n"
    end
    @engine.register_participant :bravo do |workitem|
      @tracer << "b:f0:#{workitem.fields['f0']}\n"
    end
    @engine.register_participant :charly do |workitem, fexp|
      @tracer << "c:f0:#{workitem.fields['f0']}:#{fexp.lookup_variable('v0')}\n"
    end

    #noisy

    assert_trace pdef, "a\nb:f0:f0val\nc:f0:f0val:v0val"
  end
end

