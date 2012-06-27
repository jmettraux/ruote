
#
# testing ruote
#
# Tue Jun  2 18:48:02 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtOnErrorTest < Test::Unit::TestCase
  include FunctionalBase

  class TroubleMaker
    include Ruote::LocalParticipant

    def consume(workitem)
      hits = (workitem.fields['hits'] || 0) + 1
      workitem.fields['hits'] = hits
      workitem.trace << "#{hits.to_s}\n"
      raise 'Houston, we have a problem !' if hits == 1
      workitem.trace << 'done.'
      reply(workitem)
    end

    def cancel(fei, flavour)
      # nothing to do
    end
  end

  def test_on_error

    pdef = Ruote.process_definition do
      sequence :on_error => 'catcher' do
        nada
      end
    end

    @dashboard.register_participant :catcher do
      tracer << "caught\n"
    end

    assert_trace('caught', pdef)

    assert_equal 1, logger.log.select { |e| e['action'] == 'fail' }.size
  end

  def test_on_error_unknown_participant_name

    pdef = Ruote.process_definition :name => 'test' do
      participant :mark_started
      sequence :on_error => :mark_failed do
        participant :bogus
      end
      participant :mark_finished
    end

    @dashboard.context.stash[:marks] = []

    @dashboard.register_participant 'mark\_.+' do |workitem|
      stash[:marks] << workitem.participant_name
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    assert_equal(
      %w[ mark_started mark_failed mark_finished ],
      @dashboard.context.stash[:marks])
  end

  def test_on_error_unknown_participant_name_2

    pdef = Ruote.process_definition :name => 'test' do
      participant :mark_started
      participant :bogus, :on_error => :mark_failed
      participant :mark_finished
    end

    @dashboard.context.stash[:marks] = []

    @dashboard.register_participant 'mark\_.+' do |workitem|
      stash[:marks] << workitem.participant_name
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    assert_equal(
      %w[ mark_started mark_failed mark_finished ],
      @dashboard.context.stash[:marks])
  end

  def test_on_error_neutralization

    pdef = Ruote.process_definition do
      sequence :on_error => 'catcher' do
        sequence :on_error => '' do
          nada
        end
      end
    end

    @dashboard.register_participant :catcher do
      tracer << "caught\n"
    end

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)
    ps = @dashboard.process(wfid)

    assert_equal(1, ps.errors.size)
  end

  def test_on_error_redo

    pdef = Ruote.process_definition do
      sequence :on_error => :redo do
        troublemaker
      end
    end

    @dashboard.register_participant :troublemaker, TroubleMaker

    assert_trace(%w[ 1 2 done. ], pdef)
  end

  def test_on_error_retry

    pdef = Ruote.process_definition do
      sequence :on_error => :retry do
        troublemaker
      end
    end

    @dashboard.register_participant :troublemaker, TroubleMaker

    assert_trace(%w[ 1 2 done. ], pdef)
  end

  def test_on_error_raise

    pdef = Ruote.define do
      sequence :on_error => :raise do
        error 'nada'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
    assert_equal 'nada', r['error']['message']
  end

  def test_on_error_undo

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        sequence :on_error => :undo do
          echo 'b'
          nemo
          echo 'c'
        end
        echo 'd'
      end
    end

    wfid = assert_trace(%w[ a b d ], pdef)

    assert_nil @dashboard.process(wfid)
  end

  def test_on_error_undo_single_expression

    @dashboard.register_participant :nemo do |wi|
      wi.fields['fail_count'] = 1
      raise 'nemo'
    end

    pdef = Ruote.process_definition do
      sequence do
        echo 'in'
        nemo :on_error => 'undo'
        echo '${f:error}|${f:fail_count}'
      end
    end

    wfid = assert_trace(%w[ in |1 ], pdef)

    assert_nil @dashboard.process(wfid)
  end

  def test_on_error_pass

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        sequence :on_error => :pass do
          echo 'b'
          nemo
          echo 'c'
        end
        echo 'd'
      end
    end

    wfid = assert_trace(%w[ a b d ], pdef)

    assert_nil @dashboard.process(wfid)
  end

  def test_missing_handler_triggers_regular_error

    pdef = Ruote.process_definition :on_error => 'failpath' do
      nemo
    end

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)
    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    assert_equal 1, logger.log.select { |e| e['action'] == 'error_intercepted' }.size
  end

  def test_on_error_at_process_level

    pdef = Ruote.process_definition :on_error => 'failpath' do
      nemo
      define :failpath do
        echo 'failed.'
      end
    end

    assert_trace('failed.', pdef)
  end

  def test_with_concurrence

    pdef = Ruote.process_definition do
      sequence do
        concurrence :on_error => 'emil' do
          alpha
          error 'nada0'
          error 'nada1'
        end
        echo 'done.'
      end
    end

    @dashboard.context.stash[:a_count] = 0
    @dashboard.context.stash[:e_count] = 0

    @dashboard.register_participant(:alpha) { |wi| stash[:a_count] += 1 }
    @dashboard.register_participant(:emil) { |wi| stash[:e_count] += 1 }

    assert_trace 'done.', pdef
    assert_equal 1, @dashboard.context.stash[:a_count]
    assert_equal 1, @dashboard.context.stash[:e_count]
  end

  def test_participant_on_error

    pdef = Ruote.process_definition do
      troublemaker :on_error => 'handle_error'
      define 'handle_error' do
        troublespotter
      end
    end

    @dashboard.register_participant :troublemaker do |wi|
      wi.fields['seen'] = true
      raise 'Beijing, we have a problem !'
    end
    @dashboard.register_participant :troublespotter do |wi|
      stash[:workitem] = wi
      tracer << 'err...'
    end

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    #er = @dashboard.process(wfid).errors.first
    #puts er.message
    #puts er.trace

    wi = @dashboard.context.stash[:workitem]

    assert_equal 'err...', @tracer.to_s
    assert_equal 'RuntimeError', wi.error['class']
    assert_equal 'Beijing, we have a problem !', wi.error['message']
    assert_equal Array, wi.error['trace'].class
    assert_equal true, wi.fields['seen']

    assert_equal(
      %w[ at class details deviations fei message trace tree ],
      wi.error.keys.sort)
  end

  class Murphy
    include Ruote::LocalParticipant

    def cancel(fei, flavour)
      # nothing to do
    end
    def consume(workitem)
      raise "something got wrong"
    end
  end

  def test_subprocess_on_error

    pdef = Ruote.process_definition do
      sequence :on_error => 'error_path' do
        murphy
      end
      define 'error_path' do
        catcher
      end
    end

    @dashboard.register do
      murphy FtOnErrorTest::Murphy
      catchall
    end

    @dashboard.launch(pdef)

    @dashboard.wait_for(:catcher)
  end

  class RescuerOne
    include Ruote::LocalParticipant
    def consume(workitem)
      @context.tracer << 'one'
      reply_to_engine(workitem)
    end
    def accept?(workitem)
      false
    end
  end
  class RescuerTwo
    include Ruote::LocalParticipant
    def consume(workitem)
      @context.tracer << 'two'
      reply_to_engine(workitem)
    end
    #def accept?(workitem)
    #  true
    #end
  end

  def test_participants_and_accept

    pdef = Ruote.process_definition do
      sequence :on_error => 'rescuer' do
        nada
      end
    end

    @dashboard.register do
      rescuer RescuerOne
      rescuer RescuerTwo
    end

    assert_trace('two', pdef)

    assert_equal 1, logger.log.select { |e| e['action'] == 'fail' }.size
  end

  # Only to show what's behind :on_error
  #
  def test_on_error_multi

    pdef = Ruote.define do
      sequence :on_error => [
        [ /unknown participant/, 'alpha' ],
        [ nil, 'bravo' ]
      ] do
        nada
      end
    end

    @dashboard.register_participant /alpha|bravo/ do |workitem|
      tracer << workitem.participant_name
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'alpha', @tracer.to_s
  end

  # Let's be open
  #
  def test_on_error_multi_nice

    pdef = Ruote.process_definition do
      sequence :on_error => [
        { /unknown participant/ => 'alpha' },
        { // => 'bravo' }
      ] do
        nada
      end
    end

    @dashboard.register_participant /alpha|bravo/ do |workitem|
      tracer << workitem.participant_name
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'alpha', @tracer.to_s
  end

  def test_on_error_multi_pass

    @dashboard.register_participant /alpha|bravo/ do |workitem|
      tracer << workitem.participant_name
    end

    pdef = Ruote.define do
      sequence :on_error => [
        { /unknown participant/ => :pass },
        { // => 'bravo' }
      ] do
        nada
      end
      echo 'done.'
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end

  def test_on_error_rewind

    pdef = Ruote.define do
      cursor :on_error => 'rewind' do
        echo 'in'
        inc 'v:counter'
        error 'fail', :if => '${v:counter} == 1'
        echo 'over.'
      end
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal %w[ in in over. ], @tracer.to_a
  end

  def test_on_error_jump_to

    pdef = Ruote.define do
      cursor :on_error => 'jump to shark' do
        alpha
        error 'fail'
        bravo
        shark
        delta
      end
    end

    @dashboard.register '.+' do |workitem|
      tracer << workitem.participant_name + "\n"
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal %w[ alpha shark delta ], @tracer.to_a
  end

  def test_on_error_var

    pdef = Ruote.define do
      define 'sub0' do
        set 'v:/a' => '$f:__error__'
      end
      sequence :on_error => 'sub0' do
        error 'nada'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal(
      'terminated',
      r['action'])
    assert_equal(
      %w[ at class details deviations fei message trace tree ],
      r['variables']['a'].keys.sort)
    assert_equal(
      [ 'error', { 'nada' => nil }, [] ],
      r['variables']['a']['tree'])
  end

  def test_on_error_kill_process

    pdef = Ruote.define do
      sequence do
        sequence :on_error => 'cancel_process' do
          nemo0
        end
        nemo1
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end

  #
  # the "second take" feature

  def test_second_take

    @dashboard.register_participant :troublemaker, TroubleMaker

    pdef = Ruote.define do
      define 'sub0' do
        set '__on_error__' => 'redo'
      end
      sequence :on_error => 'sub0' do
        troublemaker
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 3, r['workitem']['fields']['_trace'].size
  end

  def test_blank_second_take

    pdef = Ruote.define do
      define 'sub0' do
        set '__on_error__' => ''
      end
      sequence :on_error => 'sub0' do
        nada
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end

  def test_second_take_raise

    pdef = Ruote.define do
      define 'sub0' do
        set '__on_error__' => 'raise'
      end
      sequence :on_error => 'sub0' do
        error 'nada'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
    assert_equal 'nada', r['error']['message']
  end

  # "stashing that for now"
  #
#  def test_second_take_skip
#
#    pdef = Ruote.define do
#      define 'sub0' do
#        set '__on_error__' => 'cancel'
#      end
#      define 'sub1' do
#        set 'sub1' => true
#      end
#      sequence :on_error => 'sub0', :on_cancel => 'sub1' do
#        error 'nada'
#      end
#    end
#
#    wfid = @dashboard.launch(pdef)
#    r = @dashboard.wait_for(wfid)
#
#    #assert_equal 'error_intercepted', r['action']
#    #assert_equal 'nada', r['error']['message']
#  end

  # behaves like 'undo' when there is no on_cancel present
  #
  def test_on_error_cancel

    pdef = Ruote.define do
      sequence :on_error => 'cancel' do
        echo 'n'
        error 'nada'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ n ], @tracer.to_a
  end

  def test_on_error_and_on_cancel

    pdef = Ruote.define do
      define 'rollback' do
        echo 'rollback'
      end
      sequence :on_cancel => 'rollback', :on_error => 'cancel_process' do
        echo 'in'
        error 'nada'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']

    assert_equal %w[ in rollback ], @tracer.to_a

    assert_equal(
      1,
      @dashboard.logger.log.select { |m| m['action'] == 'cancel_process' }.size)
  end

  def test_on_error_immediate

    pdef = Ruote.define do
      define 'rollback' do
        echo 'rollback'
      end
      sequence :on_error => '!kill_process' do
        sequence :on_cancel => 'rollback' do
          echo 'in'
          error 'nada'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ in ], @tracer.to_a

    assert_nil @dashboard.ps(wfid)
  end

  def test_on_error_immediate_with_tree

    pdef = Ruote.define do
      define 'rollback' do
        echo 'rollback'
      end
      sequence :on_error => [ '!kill_process', {}, [] ] do
        sequence :on_cancel => 'rollback' do
          echo 'in'
          error 'nada'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ in ], @tracer.to_a

    assert_nil @dashboard.ps(wfid)
  end
end

