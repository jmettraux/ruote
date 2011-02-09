
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

  def test_filter_restore

    pdef = Ruote.define do
      set 'v:f' => {
        :in => [],
        :out => [
          { :fields => '/^protected_/', :restore => true },
          { :fields => '__result__', :del => true }
        ]
      }
      sequence :filter => 'f' do
        bravo
        echo '${f:protected_thing}'
      end
    end

    @engine.register :bravo do |wi|
      wi.fields['protected_thing'] = 'stolen'
      wi.fields['other_thing'] = 'stolen'
    end

    #noisy

    wfid = @engine.launch(
      pdef,
      'protected_thing' => 'here', 'other_thing' => 'here')

    r = @engine.wait_for(wfid)

    assert_equal(
      { 'protected_thing' => 'here', 'other_thing' => 'stolen' },
      r['workitem']['fields'])
  end

  def test_broken_filter_apply

    pdef = Ruote.define do
      alpha :filter => 'f'
    end

    @engine.register :alpha, Ruote::NoOpParticipant

    #noisy

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(wfid)

    assert_not_nil r['error']
    assert_equal 'ArgumentError', r['error']['class']
  end

  def test_broken_filter_reply

    pdef = Ruote.define do
      set 'v:f' => {
        :in => [],
        :out => 'nada'
      }
      alpha :filter => 'f'
    end

    @engine.register :alpha, AlphaParticipant

    #noisy

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(wfid)

    assert_not_nil r['error']
    assert_equal 'ArgumentError', r['error']['class']
  end
end

