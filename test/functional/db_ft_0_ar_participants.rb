
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Mar  6 15:13:40 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'test/ar_test_connection'
require 'openwfe/extras/participants/ar_participants'


class DbFtArParticipantsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_sequence

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        alpha
        bravo
      end
    end

    @engine.register_participant 'alpha', OpenWFE::Extras::ArParticipant
    @engine.register_participant 'bravo', OpenWFE::Extras::ArParticipant

    li = OpenWFE::LaunchItem.new(pdef)
    li.brand = 'maserati'

    clear_workitems

    @engine.launch(li)

    sleep 0.350

    wis = OpenWFE::Extras::ArWorkitem.find(:all)

    assert_equal 1, wis.size

    wi = wis.first

    assert_equal '0.0.0', wi.expid
    assert_equal 'alpha', wi.participant_name

    wi.delete
    @engine.reply(wi.as_owfe_workitem)

    sleep 0.350

    wis = OpenWFE::Extras::ArWorkitem.find(:all)

    assert_equal 1, wis.size

    wi = wis.first

    assert_equal '0.0.1', wi.expid
    assert_equal 'bravo', wi.participant_name

    wi.delete
    @engine.reply(wi.as_owfe_workitem)

    sleep 0.350

    assert_engine_clean
    purge_engine
  end

  def test_flatten_keywords_0

    assert_flattened(
      '|a:b|c:d|',
      { 'a' => 'b', 'c' => 'd' })
    assert_flattened(
      '|a:b|c:d|e:|f|g|h|',
      { 'a' => 'b', 'c' => 'd', 'e' => %w{ f g h } })
    assert_flattened(
      '|a:b|c:|d:e|f:g|h:|i|j|',
      { 'a' => 'b', 'c' => { 'd' => 'e', 'f' => 'g', 'h' => %w{ i j } } })
    assert_flattened(
      '|a:b,c|d:e, f|',
      { 'a' => 'b,c', 'd' => 'e, f' })
    assert_flattened(
      '|a:bc|d:e f|',
      { 'a' => 'b|c', 'd' => 'e| f' })
  end

  def test_search_workitems

    pdef = OpenWFE.process_definition :name => 'test' do
      participant '${f:target}'
    end

    @engine.register_participant 'alpha', OpenWFE::Extras::ArParticipant
    @engine.register_participant 'bravo', OpenWFE::Extras::ArParticipant

    launch(pdef, 'target' => 'alpha')
    launch(pdef, 'target' => 'bravo')

    sleep 0.350

    assert_equal(
      1,
      OpenWFE::Extras::ArWorkitem.search('participant:alpha', nil).size)
    assert_equal(
      2,
      OpenWFE::Extras::ArWorkitem.search('target:', nil).size)
    assert_equal(
      1,
      OpenWFE::Extras::ArWorkitem.search(':bravo', nil).size)

    OpenWFE::Extras::ArWorkitem.destroy_all
    purge_engine
  end

  def launch (pdef, fields)
    li = OpenWFE::LaunchItem.new(pdef)
    li.fields = li.fields.merge(fields)
    @engine.launch(li)
  end

  protected

  def clear_workitems
    OpenWFE::Extras::ArWorkitem.delete_all
  end

  def assert_flattened (target, h)

    assert_equal(target, OpenWFE::Extras::ArWorkitem.flatten_keywords(h, nil))
  end
end

