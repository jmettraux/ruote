
#
# testing ruote
#
# Wed Jun 10 11:03:26 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtTagsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_tag

    pdef = Ruote.process_definition do
      sequence :tag => 'main' do
        alpha :tag => 'part'
      end
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    ps = @dashboard.process(wfid)

    #p ps.variables
    #ps.expressions.each { |e| p [ e.fei, e.variables ] }
    assert_equal '0_0', ps.variables['main']['expid']
    assert_equal '0_0_0', ps.variables['part']['expid']

    #logger.log.each { |e| puts e['action'] }
    assert_equal 2, logger.log.select { |e| e['action'] == 'entered_tag' }.size

    alpha.proceed(alpha.first)
    wait_for(wfid)

    assert_equal 2, logger.log.select { |e| e['action'] == 'left_tag' }.size
  end

  # making sure a tag is removed in case of on_cancel
  #
  def test_on_cancel

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      sequence do
        sequence :tag => 'a', :on_cancel => 'decom' do
          alpha
        end
        bravo
      end
      define 'decom' do
        charly
      end
    end

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, @dashboard.process(wfid).tags.size

    fei = @dashboard.process(wfid).expressions.find { |e|
      e.fei.expid == '0_1_0'
    }.fei

    @dashboard.cancel_expression(fei)

    wait_for(:charly)

    assert_equal 1, @dashboard.process(wfid).tags.size

    @dashboard.storage_participant.proceed(@dashboard.storage_participant.first)

    wait_for(:bravo)

    ps = @dashboard.process(wfid)

    assert_equal 0, ps.tags.size
    assert_equal 1, ps.past_tags.size
    assert_equal 'a', ps.root_expression.variables['__past_tags__'].first.first

    @dashboard.storage_participant.proceed(@dashboard.storage_participant.first)

    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']

    assert_equal 1, r['variables']['__past_tags__'].size

    a = r['variables']['__past_tags__'].first

    assert_equal 'a', a[0]
    assert_match /^0_1_0!/, a[1]
    assert_match /!#{wfid}$/, a[1]
    assert_equal 'cancelled', a[2]
    assert_match /\sUTC$/, a[3]
  end

  def test_cancel_tag

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.define do
      sequence :tag => 'a' do
        alpha
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(:alpha)

    ps = @dashboard.ps(wfid)
    @dashboard.cancel(ps.expressions[1])

    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 1, r['variables']['__past_tags__'].size

    a = r['variables']['__past_tags__'].first

    assert_equal 'a', a[0]
    assert_equal 'cancelled', a[2]
  end

  def test_kill_tag

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.define do
      sequence :tag => 'a' do
        alpha
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(:alpha)

    ps = @dashboard.ps(wfid)
    @dashboard.kill(ps.expressions[1])

    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 1, r['variables']['__past_tags__'].size

    a = r['variables']['__past_tags__'].first

    assert_equal 'a', a[0]
    assert_equal 'killed', a[2]
  end

  def test_unset_tag_when_parent_gone

    pdef = Ruote.process_definition do
      concurrence :count => 1 do
        alpha :tag => 'main'
        sequence do
          bravo
          undo :ref => 'main'
        end
      end
    end

    @dashboard.register :alpha, Ruote::NullParticipant
    @dashboard.register :bravo, Ruote::NoOpParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(23)

    assert_nil @dashboard.process(wfid)
  end

  def test_tags_and_workitems

    pdef = Ruote.define do
      sequence :tag => 'first-stage' do
        alpha
      end
      sequence :tag => 'second-stage' do
        bravo
        charly :tag => 'third-stage'
      end
      david
    end

    @dashboard.register { catchall }

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(:alpha)
    wi = @dashboard.storage_participant.first

    assert_equal %w[ first-stage ], wi.tags

    @dashboard.storage_participant.proceed(wi)
    @dashboard.wait_for(:bravo)
    wi = @dashboard.storage_participant.first

    assert_equal %w[ second-stage ], wi.tags

    @dashboard.storage_participant.proceed(wi)
    @dashboard.wait_for(:charly)
    wi = @dashboard.storage_participant.first

    assert_equal %w[ second-stage third-stage ], wi.tags

    @dashboard.storage_participant.proceed(wi)
    @dashboard.wait_for(:david)
    wi = @dashboard.storage_participant.first

    assert_equal [], wi.tags
  end

  # Cf http://groups.google.com/group/openwferu-users/browse_thread/thread/61f037bc491dcf4c
  #
  def test_tags_workitems_and_cursor

    pdef = Ruote.define do
      sequence :tag => 'phase1' do
        concurrence :merge_type => :union do
          alpha
          bravo
        end
        charly
      end
    end

    @dashboard.register_participant '.+' do |workitem|
      if workitem.participant_name == 'charly'
        workitem.fields['tags'] = workitem.fields['__tags__'].dup
      end
      nil
    end

    wfid = @dashboard.launch(pdef, 'my_array' => [ 1 ])
    r = @dashboard.wait_for(wfid)

    assert_equal(%w[ phase1 ], r['workitem']['fields']['tags'])
    assert_equal('phase1', r['workitem']['fields']['__left_tag__'])
    assert_equal([], r['workitem']['fields']['__tags__'])
  end

  def test_tag_and_define

    pdef = Ruote.define :tag => 'nada' do
      alpha
    end

    @dashboard.register 'alpha', Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(:alpha)

    assert_equal 1, logger.log.select { |e| e['action'] == 'entered_tag' }.size

    wi = @dashboard.storage_participant.first
    @dashboard.storage_participant.proceed(wi)

    @dashboard.wait_for(wfid)

    assert_equal 1, logger.log.select { |e| e['action'] == 'left_tag' }.size
  end

  def test_absolute_tags

    pdef = Ruote.define do
      concurrence do
        sequence do
          listen :to => 'b', :upon => 'entering'
          echo 'b'
        end
        sequence do
          listen :to => 'a/b', :upon => 'entering'
          echo 'a/b'
        end
        sequence :tag => 'a' do
          wait '1s'
          sequence :tag => 'b' do
          end
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal %w[ a/b b ], @tracer.to_a.sort

    past_tags = r['variables']['__past_tags__']

    assert_equal(
      %w[ a a/b ],
      past_tags.collect(&:first).sort)

    past_tag = past_tags.first

    assert_equal(
      [ String, String, NilClass, String, NilClass ], past_tag.collect(&:class))

    assert_equal(
      Ruote::FlowExpressionId, Ruote.extract_fei(past_tag[1]).class)
    assert_match(
      / UTC$/, past_tag[3])
  end

  def test_tags_and_re_apply

    @dashboard.register_participant :look_at_tags do |workitem|
      tracer << workitem.tags.join('/') + "\n"
    end

    pdef = Ruote.define do
      sequence :tag => 'alpha' do
        look_at_tags
        error 'nada'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for('error_intercepted')

    seq = @dashboard.ps(wfid).expressions[1]
    @dashboard.re_apply(seq)

    r = @dashboard.wait_for('error_intercepted')

    assert_equal %w[ alpha alpha ], @tracer.to_a
  end

  def test_tag_and_on_handler

    pdef = Ruote.define do
      define 'h' do
        echo 'in_handler'
        wait '1s'
        echo 'handler_out'
      end
      concurrence do
        sequence do
          await :left_tag => 'alpha'
          echo 'left_tag'
        end
        sequence :tag => 'alpha', :on_error => 'h' do
          error 'nada'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']

    assert_equal %w[ in_handler handler_out left_tag ], @tracer.to_a
  end

  # Those empty tags tests were fixed during the Fukuoka RubyKaigi 01
  # (2012/12/01).
  #
  def test_empty_tag

    pdef = Ruote.define do
      noop :tag => ''
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end

  def test_empty_untrimmed_tag

    pdef = Ruote.define do
      noop :tag => ' '
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end
end

