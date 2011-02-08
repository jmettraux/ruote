
#
# testing ruote
#
# Tue Feb  8 12:39:35 JST 2011
#

require File.join(File.dirname(__FILE__), 'base')


class FtFilterAttributeTest < Test::Unit::TestCase
  include FunctionalBase

  class AlphaParticipant
    include Ruote::LocalParticipant

    def consume(workitem)

      @context.tracer << 'fields: ' + workitem.fields.keys.sort.join(' ') + "\n"

      reply_to_engine(workitem)
    end
  end

  def test_filter_in_variable

    pdef = Ruote.define do
      set 'v:f' => {
        :in => [ { :fields => '/^private_/', :remove => true } ],
        :out => [ { :fields => '/^~~.private_/', :merge_to => '.' } ]
      }
      alpha :filter => 'f'
      alpha
    end

    @engine.register :alpha, AlphaParticipant

    #noisy

    wfid = @engine.launch(
      pdef,
      'private_a' => 'x', 'a' => 'y')

    @engine.wait_for(wfid)

    assert_equal(
      "fields: a dispatched_at params\n" +
      "fields: a dispatched_at params private_a",
      @tracer.to_s)
  end

  def test_broken_filter_apply

    flunk
  end
end

