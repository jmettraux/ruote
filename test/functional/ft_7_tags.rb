
#
# testing ruote
#
# Wed Jun 10 11:03:26 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class FtTagsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_tag

    pdef = Ruote.process_definition do
      sequence :tag => 'main' do
        alpha :tag => 'part'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    ps = @engine.process(wfid)

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

    pdef = Ruote.process_definition do
      sequence do
        sequence :tag => 'a', :on_cancel => 'decom' do
          alpha
        end
        alpha
      end
      define 'decom' do
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, @engine.process(wfid).tags.size

    fei = @engine.process(wfid).expressions.find { |e|
      e.fei.expid == '0_1_0'
    }.fei

    @engine.cancel_expression(fei)

    wait_for(:alpha)

    assert_equal 0, @engine.process(wfid).tags.size

    alpha.proceed(alpha.first)

    wait_for(:alpha)

    assert_equal 0, @engine.process(wfid).tags.size
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

    #@engine.noisy = true

    @engine.register :alpha, Ruote::NullParticipant
    @engine.register :bravo, Ruote::NoOpParticipant

    wfid = @engine.launch(pdef)

    @engine.wait_for(23)

    assert_nil @engine.process(wfid)
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

    @engine.register { catchall }

    wfid = @engine.launch(pdef)
    @engine.wait_for(:alpha)
    wi = @engine.storage_participant.first

    assert_equal %w[ first-stage ], wi.tags

    @engine.storage_participant.proceed(wi)
    @engine.wait_for(:bravo)
    wi = @engine.storage_participant.first

    assert_equal %w[ second-stage ], wi.tags

    @engine.storage_participant.proceed(wi)
    @engine.wait_for(:charly)
    wi = @engine.storage_participant.first

    assert_equal %w[ second-stage third-stage ], wi.tags

    @engine.storage_participant.proceed(wi)
    @engine.wait_for(:david)
    wi = @engine.storage_participant.first

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

    @engine.register_participant '.+' do |workitem|
      if workitem.participant_name == 'charly'
        workitem.fields['tags'] = workitem.fields['__tags__'].dup
      end
      nil
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef, 'my_array' => [ 1 ])
    r = @engine.wait_for(wfid)

    assert_equal(%w[ phase1 ], r['workitem']['fields']['tags'])
    assert_equal([], r['workitem']['fields']['__tags__'])
  end

  def test_tag_and_define

    pdef = Ruote.define :tag => 'nada' do
      alpha
    end

    @engine.register 'alpha', Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)
    @engine.wait_for(:alpha)

    assert_equal 1, logger.log.select { |e| e['action'] == 'entered_tag' }.size

    wi = @engine.storage_participant.first
    @engine.storage_participant.proceed(wi)

    @engine.wait_for(wfid)

    assert_equal 1, logger.log.select { |e| e['action'] == 'left_tag' }.size
  end
end

