
#
# testing ruote
#
# Thu Jun 11 15:24:47 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftConcurrenceTest < Test::Unit::TestCase
  include FunctionalBase

  def test_basic

    pdef = Ruote.process_definition do
      concurrence do
        alpha
        alpha
      end
    end

    @dashboard.register_participant :alpha do
      tracer << "alpha\n"
    end

    assert_trace %w[ alpha alpha ], pdef
  end

  def test_empty

    pdef = Ruote.process_definition do
      concurrence do
      end
      echo 'done.'
    end

    assert_trace %w[ done. ], pdef
  end

  def test_accidental_empty

    @dashboard.register_participant :nada do
      tracer << "nada\n"
    end

    pdef = Ruote.process_definition do
      concurrence do
        nada :if => false
      end
      echo 'done.'
    end

    assert_trace %w[ done. ], pdef
  end

  def test_over_if

    pdef = Ruote.process_definition do
      concurrence :over_if => "${f:seen}", :merge_type => :isolate do
        alpha
        alpha
        alpha
      end
      bravo
    end

    stash[:count] = 0

    alpha = @dashboard.register :alpha, 'do_not_thread' => true do |wi|
      wi.fields['seen'] = 'indeed' if stash[:count] == 1
      tracer << "alpha\n"
      stash[:count] += 1
      nil
    end

    @dashboard.register_participant :bravo do |workitem|
      stash[:fields] = workitem.fields
      nil
    end

    assert_trace(%w[ alpha ] * 3, pdef)

    #assert_equal(
    #  {'1'=>{"seen"=>"indeed"}, '0'=>{}, "params"=>{"ref"=>"bravo"}},
    #  fields)

    params = @dashboard.context.stash[:fields].delete('params')

    assert_equal({ 'ref' => 'bravo' }, params)
    assert_match /seen/, @dashboard.context.stash[:fields].inspect
  end

  def test_over_if__remaining_cancel

    @dashboard.register 'alpha', Ruote::StorageParticipant

    pdef = Ruote.define do
      concurrence :over_if => '${seen}' do
        alpha
        alpha
      end
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('dispatched')

    wi = @dashboard.storage_participant.first

    wi.fields['seen'] = true
    @dashboard.storage_participant.proceed(wi)

    @dashboard.wait_for('dispatch_cancel')
    sleep 0.350

    assert_equal 0, @dashboard.storage_participant.size
  end

  def test_over_if__post

    @dashboard.register :alpha do |workitem|
      tracer << "alpha\n"
      workitem.fields['ok'] = 'yes'
    end
    @dashboard.register :bravo do |workitem|
      sleep 0.5
      tracer << "bravo\n"
    end
    @dashboard.register :zulu do |workitem|
      tracer << "zulu\n"
    end

    pdef = Ruote.define do
      set 'f:ok' => 'no'
      concurrence :over_if => '${f:ok} == yes' do
      #concurrence :over_if => '${f:ok} == yes', :merge_type => 'mix' do
        alpha
        bravo :if => 'false'
      end
      zulu :if => '${f:ok} == yes'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 'yes', r['workitem']['fields']['ok']
    assert_equal %w[ alpha zulu ], @tracer.to_a
  end

  def test_over_unless

    pdef = Ruote.process_definition do
      set 'f:ok' => 'true'
      concurrence :over_unless => '${f:ok}', :merge_type => :isolate do
        alpha
        alpha
        alpha
      end
      echo 'done.'
    end

    stash[:count] = 0

    alpha = @dashboard.register :alpha, 'do_not_thread' => true do |wi|
      if stash[:count] > 1
        wi.fields['ok'] = false
      else
        tracer << "a\n"
        stash[:count] += 1
      end
    end

    fields = nil

    @dashboard.register_participant :bravo do |workitem|
      fields = workitem.fields
    end

    assert_trace(%w[ a a done. ], pdef)
  end

  def test_remaining_forget_when_no_remains

    pdef = Ruote.process_definition do
      concurrence :remaining => :forget do
        echo 'a'
        echo 'b'
      end
      echo 'done.'
    end

    assert_trace %w[ a b done. ], %w[ b a done. ], pdef
  end

  # helper
  #
  def run_concurrence(concurrence_attributes)

    reverse_reply_order = concurrence_attributes.delete(:_reverse_reply_order)

    pdef = Ruote.define do
      concurrence(concurrence_attributes) do
        alpha
        alpha
        alpha
      end
      alpha
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    3.times { wait_for('dispatched') }

    wis = @dashboard.storage_participant.to_a
    wis.reverse! if reverse_reply_order
    wis.each do |wi|
      wi.fields['seen'] = wi.fei.expid
      wi.fields[wi.fei.expid] = 'alpha'
      wi.fields['a'] = [ wi.fei.expid, 'x' ]
      wi.fields['h'] = { wi.fei.expid => 9 }
      alpha.proceed(wi)
    end

    wait_for(:alpha)

    wi = alpha.first

    ps = @dashboard.process(wi.fei.wfid)
    assert_equal %w[ 0 0_1 ], ps.expressions.collect { |e| e.fei.expid }.sort

    wi
  end

  #
  # merge tests

  def test_default_merge # first

    wi = run_concurrence({})

    assert_equal '0_0_0', wi.fields['seen']
  end

  def test_default_merge__reverse # first

    wi = run_concurrence(:_reverse_reply_order => true)

    assert_equal '0_0_2', wi.fields['seen']
  end

  def test_merge_last

    wi = run_concurrence(:merge => :last)

    assert_equal '0_0_2', wi.fields['seen']
  end

  def test_merge_last__reverse

    wi = run_concurrence(:merge => :last, :_reverse_reply_order => true)

    assert_equal '0_0_0', wi.fields['seen']
  end

  def test_merge_highest

    wi = run_concurrence(:merge => :highest)

    assert_equal '0_0_0', wi.fields['seen']
  end

  def test_merge_highest__reverse

    wi = run_concurrence(:merge => :highest, :_reverse_reply_order => true)

    assert_equal '0_0_0', wi.fields['seen']
  end

  def test_merge_lowest

    wi = run_concurrence(:merge => :lowest)

    assert_equal '0_0_2', wi.fields['seen']
  end

  def test_merge_lowest__reverse

    wi = run_concurrence(:merge => :lowest, :_reverse_reply_order => true)

    assert_equal '0_0_2', wi.fields['seen']
  end

  #
  # merge_type tests

  #def test_merge_type_override # already tested above
  #end

  def test_merge_type_mix

    wi = run_concurrence(:merge_type => :mix)

    assert_equal(
      %w[ 0_0_0 0_0_1 0_0_2 a dispatched_at h params seen ],
      wi.fields.keys.collect { |k| k.to_s }.sort)

    assert_equal('0_0_0', wi.fields['seen'])
  end

  def test_merge_type_isolate

    wi = run_concurrence(:merge_type => :isolate)

    assert_equal(
      %w[ 0 1 2 dispatched_at params ],
      wi.fields.keys.collect { |k| k.to_s }.sort)

    assert_equal({ 'ref' => 'alpha' }, wi.fields['params'])
    assert_equal(%w[ 0_0_0 a h seen ], wi.fields['0'].keys.sort)
    assert_equal(%w[ 0_0_1 a h seen ], wi.fields['1'].keys.sort)
    assert_equal(%w[ 0_0_2 a h seen ], wi.fields['2'].keys.sort)
  end

  def test_merge_type_stack

    wi = run_concurrence(:merge_type => :stack)

    assert_equal(
      %w[ dispatched_at params stack stack_attributes ],
      wi.fields.keys.collect { |k| k.to_s }.sort)

    assert_equal({ 'ref' => 'alpha' }, wi.fields['params'])
    assert_equal(%w[ 0_0_0 a h seen ], wi.fields['stack'][0].keys.sort)
    assert_equal(%w[ 0_0_1 a h seen ], wi.fields['stack'][1].keys.sort)
    assert_equal(%w[ 0_0_2 a h seen ], wi.fields['stack'][2].keys.sort)
  end

  def test_merge_type_union

    wi = run_concurrence(:merge_type => :union)

    assert_equal(
      %w[ 0_0_0 0_0_1 0_0_2 a dispatched_at h params seen ],
      wi.fields.keys.collect { |k| k.to_s }.sort)

    assert_equal('0_0_2', wi.fields['seen'])
    assert_equal(%w[ 0_0_0 x 0_0_1 0_0_2 ], wi.fields['a'])
    assert_equal(%w[ 0_0_0 0_0_1 0_0_2 ], wi.fields['h'].keys.sort)
  end

  def test_merge_type_concat

    wi = run_concurrence(:merge_type => :concat)

    assert_equal(
      %w[ 0_0_0 0_0_1 0_0_2 a dispatched_at h params seen ],
      wi.fields.keys.collect { |k| k.to_s }.sort)

    assert_equal('0_0_2', wi.fields['seen'])
    assert_equal(%w[ 0_0_0 x 0_0_1 x 0_0_2 x], wi.fields['a'])
    assert_equal(%w[ 0_0_0 0_0_1 0_0_2 ], wi.fields['h'].keys.sort)
  end

  # not deep enough though
  #
  def test_merge_type_deep

    wi = run_concurrence(:merge_type => :deep)

    assert_equal(
      %w[ 0_0_0 0_0_1 0_0_2 a dispatched_at h params seen ],
      wi.fields.keys.collect { |k| k.to_s }.sort)

    assert_equal('0_0_2', wi.fields['seen'])
    assert_equal(%w[ 0_0_0 x 0_0_1 x 0_0_2 x ], wi.fields['a'])
    assert_equal(%w[ 0_0_0 0_0_1 0_0_2 ], wi.fields['h'].keys.sort)
  end

  def test_merge_type_ignore

    wi = run_concurrence(:merge_type => :ignore)

    assert_equal(
      %w[ dispatched_at params ], wi.fields.keys.collect { |k| k.to_s }.sort)
  end

  #
  # count tests

  # helper
  #
  def run_test_count(remaining)

    pdef = Ruote.process_definition do
      concurrence :count => 1, :remaining => remaining do
        alpha
        bravo
      end
    end

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    @dashboard.storage_participant.proceed(@dashboard.storage_participant.first)

    wait_for(wfid)

    wfid
  end

  def test_count

    wfid = run_test_count('cancel')

    #puts
    #logger.log.each { |e| p e }
    #puts
    assert_equal 1, logger.log.select { |e| e['action'] == 'cancel' }.size

    sleep 0.350 # since now dispatch_cancel occurs asynchronously...

    assert_equal 0, @dashboard.storage_participant.size
  end

  def test_count_remaining_forget

    wfid = run_test_count('forget')

    #assert_equal 1, logger.log.select { |e| e['action'] == 'forget' }.size

    assert_equal 1, @dashboard.storage_participant.size
    assert_equal 'bravo', @dashboard.storage_participant.first.participant_name

    #@dashboard.context.storage.get_many('expressions').each { |e| p e['fei'] }
    #puts @dashboard.context.storage.dump('expressions')
    #p @dashboard.ps(wfid)
    assert_equal 2, @dashboard.context.storage.get_many('expressions').size
    assert_not_nil @dashboard.process(wfid)

    @dashboard.storage_participant.proceed(@dashboard.storage_participant.first)

    wait_for(wfid)

    @dashboard.context.storage.get_many('expressions').each { |e| p e['fei'] }
    assert_equal 0, @dashboard.context.storage.get_many('expressions').size
  end

  def test_count_negative

    pdef = Ruote.define do
      concurrence :mt => 'mix', :c => -1 do # all but 1
        set 'a' => 1
        set 'b' => 2
        set 'c' => 3
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 1, r['workitem']['fields']['a']
    assert_equal 2, r['workitem']['fields']['b']
    assert_equal nil, r['workitem']['fields']['c']
  end

  def test_cancel

    pdef = Ruote.process_definition do
      concurrence do
        alpha
        alpha
      end
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)

    assert_equal 2, alpha.size

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_nil ps
  end

  #
  # 'wait_for' tests

  # 'wait_for => 1' is equivalent to 'count => 1'
  #
  def test_wait_for_int

    pdef = Ruote.define do
      concurrence :wait_for => 1 do
        sequence do
          stall
          echo 'alpha'
        end
        echo 'bravo'
      end
      echo 'over.'
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal %w[ bravo over. ], @tracer.to_a
  end

  def test_wait_for_zero

    pdef = Ruote.define do
      concurrence :wait_for => 0, :remaining => :forget do
        sequence do
          wait '5s'
          echo 'alpha'
        end
      end
      echo 'over.'
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal %w[ over. ], @tracer.to_a
  end

  def test_wait_for_tags

    pdef = Ruote.define do
      concurrence :wait_for => 'azuma, bashamichi', :merge_type => 'concat' do
        sequence :tag => 'azuma' do
          set 'seen' => [ 'azuma' ]
        end
        sequence :tag => 'bashamichi' do
          set 'seen' => [ 'bashamichi' ]
        end
        sequence :tag => 'katou' do
          set 'seen' => [ 'katou' ]
        end
      end
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal %w[ azuma bashamichi ], r['workitem']['fields']['seen'].sort
  end

  def test_wait_for_tags_array

    pdef = Ruote.define do
      concurrence :wait_for => %w[ azuma bashamichi ], :mt => 'concat' do
        sequence :tag => 'azuma' do
          set 'seen' => [ 'azuma' ]
        end
        sequence :tag => 'bashamichi' do
          set 'seen' => [ 'bashamichi' ]
        end
        sequence :tag => 'katou' do
          set 'seen' => [ 'katou' ]
          wait '5s'
        end
      end
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal %w[ azuma bashamichi ], r['workitem']['fields']['seen'].sort
  end

  def test_wait_for_one_tag

    @dashboard.register do
      administrator do |workitem|
        tracer << "administrator\n"
        sleep 0.7
      end
      evaluator Ruote::NullParticipant
      #evaluator Ruote::NoOpParticipant
    end

    pdef = Ruote.process_definition do
     concurrence :wait_for => 'first' do
       sequence :tag => 'first' do
         administrator
       end
       sequence :tag => 'second' do
         evaluator
       end
     end
     echo 'done.'
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal "administrator\ndone.", @tracer.to_s
  end

  def test_wait_for_unknown_tag

    pdef = Ruote.define do
      concurrence :wait_for => 'nada' do
        echo 'a'
        echo 'b'
      end
      echo 'c'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'ceased', r['action']
    assert_equal %w[ a b ], @tracer.to_a.sort
  end

  def test_remaining_wait

    pdef = Ruote.define do
      concurrence :count => 1, :rem => 'wait', :mt => 'mix' do
        set 'a' => true
        sequence do
          set 'b' => true
          stall
        end
      end
    end

    wfid = @dashboard.launch(pdef); r = @dashboard.wait_for(wfid)

    assert_equal(
      { 'a' => true, 'b' => true, '__result__' => true },
      r['workitem']['fields'])
  end
end

