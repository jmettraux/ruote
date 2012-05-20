
#
# testing ruote
#
# Tue Feb  8 12:39:35 JST 2011
#

require File.expand_path('../base', __FILE__)


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

    @dashboard.register :alpha, AlphaParticipant

    wfid = @dashboard.launch(
      pdef,
      'private_a' => 'x', 'a' => 'y')

    @dashboard.wait_for(wfid)

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

    @dashboard.register :bravo do |wi|
      wi.fields['protected_thing'] = 'stolen'
      wi.fields['other_thing'] = 'stolen'
    end

    wfid = @dashboard.launch(
      pdef,
      'protected_thing' => 'here', 'other_thing' => 'here')

    r = @dashboard.wait_for(wfid)

    assert_equal(
      { 'protected_thing' => 'here', 'other_thing' => 'stolen' },
      r['workitem']['fields'])
  end

  def test_broken_filter_apply

    pdef = Ruote.define do
      alpha :filter => 'f'
    end

    @dashboard.register :alpha, Ruote::NoOpParticipant

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

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

    @dashboard.register :alpha, AlphaParticipant

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_not_nil r['error']
    assert_equal 'ArgumentError', r['error']['class']
  end

  class AaFilterParticipant
    def consume(wi)
      (wi.fields['seen'] ||= []) << wi.fields['__filter_direction__']
    end
  end

  def test_filter_participant__consume

    pdef = Ruote.define do
      alpha :filter => 'filter_a'
    end

    @dashboard.register :alpha, AlphaParticipant
    @dashboard.register :filter_a, AaFilterParticipant

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_nil r['workitem']['fields']['__filter_direction__']
    assert_equal %w[ in out ], r['workitem']['fields']['seen']
    assert_equal 'fields: dispatched_at params seen', @tracer.to_s
  end

  class BbFilterParticipant
    def filter(fields, direction)
      (fields['seen'] ||= []) << direction
      fields
    end
  end

  def test_filter_participant__filter

    pdef = Ruote.define do
      alpha :filter => 'filter_b'
    end

    @dashboard.register :alpha, AlphaParticipant
    @dashboard.register :filter_b, BbFilterParticipant

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal %w[ in out ], r['workitem']['fields']['seen']
    assert_equal 'fields: dispatched_at params seen', @tracer.to_s
  end

  class CcFilterParticipant
    def consume(wi)
      raise 'something goes horribly wrong'
    end
  end

  def test_filter_participant_with_error

    pdef = Ruote.define do
      alpha :filter => 'filter_c'
    end

    @dashboard.register :alpha, AlphaParticipant
    @dashboard.register :filter_c, CcFilterParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal 1, @dashboard.ps(wfid).errors.size
    assert_equal '', @tracer.to_s
  end

  class DdFilterParticipant
    def consume(workitem)
      workitem.fields[workitem.participant_name] =
        workitem.fields['__filter_direction__']
    end
  end

  def test_filter_participant__in_and_out

    pdef = Ruote.define do
      alpha :filter => { :in => 'f0', :out => 'f1' }
    end

    @dashboard.register :alpha, AlphaParticipant
    @dashboard.register :f0, DdFilterParticipant
    @dashboard.register :f1, DdFilterParticipant

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal({ 'f0' => 'in', 'f1' => 'out' }, r['workitem']['fields'])
    assert_equal('fields: dispatched_at f0 params', @tracer.to_s)
  end

  def test_filter_empty

    @dashboard.register '.+' do |workitem|
      context.tracer << workitem.participant_name + "\n"
    end

    pdef = Ruote.define do
      alpha :filter => {}
      bravo :filter => { 'in' => [] }
      charly :filter => { 'out' => [] }
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal %w[ alpha bravo charly ], @tracer.to_a
  end

  def test_cancel_after_error

    @dashboard.register :alpha, Ruote::NoOpParticipant

    pdef = Ruote.define do
      alpha :filter => { :in => [ { :field => 'x', :type => :number } ] }
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('error_intercepted')

    @dashboard.cancel(wfid)

    @dashboard.wait_for('terminated')

    assert_nil @dashboard.ps(wfid)
  end

  def test_cancel_after_error_out

    @dashboard.register :alpha, Ruote::NoOpParticipant

    pdef = Ruote.define do
      alpha :filter => { :out => [ { :field => 'x', :type => :number } ] }
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('error_intercepted')

    @dashboard.cancel(wfid)

    @dashboard.wait_for('terminated')

    assert_nil @dashboard.ps(wfid)
  end

#  def test_filter_record
#
#    pdef = Ruote.define do
#      set 'v:f' => {
#        :in => [ { :fields => 'x', :type => 'number' } ],
#        :out => []
#      }
#      alpha :filter => 'f'
#    end
#
#    @dashboard.register :alpha, AlphaParticipant
#
#    wfid = @dashboard.launch(
#      pdef,
#      'x' => 'not a number')
#
#    @dashboard.wait_for(wfid)
#
#    assert_equal(
#      "fields: a dispatched_at params\n" +
#      "fields: a dispatched_at params private_a",
#      @tracer.to_s)
#  end
  #
  # in the fridge for now

end

