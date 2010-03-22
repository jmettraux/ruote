
#
# testing ruote
#
# Thu Jun 11 15:24:47 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


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

    count = 0

    alpha = @engine.register_participant :alpha do |workitem|
      workitem.fields['seen'] = 'indeed' if count == 1
      @tracer << "alpha\n"
      count = count + 1
      nil
    end
    alpha.do_not_thread = true

    fields = nil

    @engine.register_participant :bravo do |workitem|
      fields = workitem.fields
      nil
    end

    #noisy

    assert_trace(%w[ alpha ] * 3, pdef)

    #assert_equal(
    #  {'1'=>{"seen"=>"indeed"}, '0'=>{}, "params"=>{"ref"=>"bravo"}},
    #  fields)

    params = fields.delete('params')

    assert_equal({ 'ref' => 'bravo' }, params)
    assert_match /seen/, fields.inspect
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

    count = 0

    alpha = @engine.register_participant :alpha do |workitem|
      if count > 1
        workitem.fields['ok'] = false
      else
        @tracer << "a\n"
        count = count + 1
      end
    end
    alpha.do_not_thread = true

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
  def run_concurrence (concurrence_attributes, noise)

    pdef = Ruote.process_definition do
      sequence do
        concurrence(concurrence_attributes) do
          alpha
          alpha
        end
      end
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    noisy if noise

    wfid = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)

    2.times do
      wi = alpha.first
      wi.fields['seen'] = wi.fei.expid
      alpha.reply(wi)
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
  def run_test_count (remaining, noise)

    pdef = Ruote.process_definition do
      concurrence :count => 1, :remaining => remaining do
        alpha
        bravo
      end
    end

    @alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new
    @bravo = @engine.register_participant :bravo, Ruote::HashParticipant.new

    noisy if noise

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    @alpha.reply(@alpha.first)

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

    assert_equal 0, @alpha.size
    assert_equal 0, @bravo.size
  end

  def test_count_remaining_forget

    #noisy

    wfid = run_test_count('forget', false)

    #assert_equal 1, logger.log.select { |e| e['action'] == 'forget' }.size

    assert_equal 0, @alpha.size
    assert_equal 1, @bravo.size

    #@engine.context.storage.get_many('expressions').each { |e| p e['fei'] }
    #puts @engine.context.storage.dump('expressions')
    assert_equal 2, @engine.context.storage.get_many('expressions').size
    assert_not_nil @engine.process(wfid)

    @bravo.reply(@bravo.first)

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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

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

