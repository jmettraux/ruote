
#
# testing ruote
#
# Thu Jun 11 15:24:47 JST 2009
#

require File.expand_path('../base', __FILE__)

#require 'ruote/part/hash_participant'


class EftConcurrenceTest < Test::Unit::TestCase
  include FunctionalBase

  def test_basic

    pdef = Ruote.process_definition do
      concurrence do
        alpha
        alpha
      end
    end

    @engine.register_participant :alpha do
      @tracer << "alpha\n"
    end

    #noisy

    assert_trace %w[ alpha alpha ], pdef
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

    @engine.context.instance_eval do
      @count = 0
    end
      # since block participants are evaluated in the context context

    alpha = @engine.register_participant :alpha, 'do_not_thread' => true do |wi|
      wi.fields['seen'] = 'indeed' if @count == 1
      @tracer << "alpha\n"
      @count = @count + 1
      nil
    end

    @engine.register_participant :bravo do |workitem|
      stash[:fields] = workitem.fields
      nil
    end

    #noisy

    assert_trace(%w[ alpha ] * 3, pdef)

    #assert_equal(
    #  {'1'=>{"seen"=>"indeed"}, '0'=>{}, "params"=>{"ref"=>"bravo"}},
    #  fields)

    params = @engine.context.stash[:fields].delete('params')

    assert_equal({ 'ref' => 'bravo' }, params)
    assert_match /seen/, @engine.context.stash[:fields].inspect
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

    @engine.context.instance_eval do
      @count = 0
    end
      # since block participants are evaluated in the context context

    alpha = @engine.register_participant :alpha, 'do_not_thread' => true do |wi|
      if @count > 1
        wi.fields['ok'] = false
      else
        @tracer << "a\n"
        @count = @count + 1
      end
    end

    fields = nil

    @engine.register_participant :bravo do |workitem|
      fields = workitem.fields
    end

    #noisy

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

    #noisy

    assert_trace %w[ a b done. ], %w[ b a done. ], pdef
  end

  # helper
  #
  def run_concurrence(concurrence_attributes, noise)

    pdef = Ruote.process_definition do
      sequence do
        concurrence(concurrence_attributes) do
          alpha
          alpha
        end
      end
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    noisy if noise

    wfid = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)

    2.times do
      wi = alpha.first
      wi.fields['seen'] = wi.fei.expid
      alpha.proceed(wi)
    end

    wait_for(:alpha)

    wi = alpha.first

    ps = @engine.process(wi.fei.wfid)
    assert_equal %w[ 0 0_1 ], ps.expressions.collect { |e| e.fei.expid }.sort

    wi
  end

  def test_default_merge

    wi = run_concurrence({}, false)

    assert_equal '0_1', wi.fei.expid
    assert_not_nil wi.fields['seen']
  end

  def test_merge_last

    wi = run_concurrence({ :merge => :last }, false)

    assert_equal '0_1', wi.fei.expid
    assert_not_nil wi.fields['seen']
  end

  def test_concurrence_merge_type_isolate

    wi = run_concurrence({ :merge_type => :isolate }, false)

    assert_equal(
      %w[ 0 1 dispatched_at params ],
      wi.fields.keys.collect { |k| k.to_s }.sort)

    assert_equal({ 'ref' => 'alpha' }, wi.fields['params'])
    assert_equal(%w[ seen ], wi.fields['0'].keys)
    assert_equal(%w[ seen ], wi.fields['1'].keys)
  end

  def test_concurrence_merge_type_stack

    wi = run_concurrence({ :merge_type => :stack }, false)

    assert_equal(
      %w[ dispatched_at params stack stack_attributes ],
      wi.fields.keys.collect { |k| k.to_s }.sort)

    assert_equal({ 'ref' => 'alpha' }, wi.fields['params'])
    assert_equal(%w[ seen ], wi.fields['stack'][0].keys)
    assert_equal(%w[ seen ], wi.fields['stack'][1].keys)
  end

  # helper
  #
  def run_test_count(remaining, noise)

    pdef = Ruote.process_definition do
      concurrence :count => 1, :remaining => remaining do
        alpha
        bravo
      end
    end

    @engine.register_participant '.+', Ruote::StorageParticipant

    noisy if noise

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    @engine.storage_participant.proceed(@engine.storage_participant.first)

    wait_for(wfid)

    wfid
  end

  def test_count

    #noisy

    wfid = run_test_count('cancel', false)

    #puts
    #logger.log.each { |e| p e }
    #puts
    assert_equal 1, logger.log.select { |e| e['action'] == 'cancel' }.size

    sleep 0.350 # since now dispatch_cancel occurs asynchronously...

    assert_equal 0, @engine.storage_participant.size
  end

  def test_count_remaining_forget

    #noisy

    wfid = run_test_count('forget', false)

    #assert_equal 1, logger.log.select { |e| e['action'] == 'forget' }.size

    assert_equal 1, @engine.storage_participant.size
    assert_equal 'bravo', @engine.storage_participant.first.participant_name

    #@engine.context.storage.get_many('expressions').each { |e| p e['fei'] }
    #puts @engine.context.storage.dump('expressions')
    assert_equal 2, @engine.context.storage.get_many('expressions').size
    assert_not_nil @engine.process(wfid)

    @engine.storage_participant.proceed(@engine.storage_participant.first)

    wait_for(wfid)

    @engine.context.storage.get_many('expressions').each { |e| p e['fei'] }
    assert_equal 0, @engine.context.storage.get_many('expressions').size
  end

  def test_cancel

    pdef = Ruote.process_definition do
      concurrence do
        alpha
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)

    assert_equal 2, alpha.size

    @engine.cancel_process(wfid)

    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_nil ps
  end
end

