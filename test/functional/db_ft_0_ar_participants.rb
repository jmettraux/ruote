
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

  def test_extract_keywords_0

    assert_extracted(
      'b d',
      { 'a' => 'b', 'c' => 'd' })
    assert_extracted(
      'b d f g h',
      { 'a' => 'b', 'c' => 'd', 'e' => %w{ f g h } })
    assert_extracted(
      'b e g i j',
      { 'a' => 'b', 'c' => { 'd' => 'e', 'f' => 'g', 'h' => %w{ i j } } })
  end

  protected

  def clear_workitems
    OpenWFE::Extras::ArWorkitem.delete_all
  end

  protected

  def assert_extracted (target, h)

    assert_equal(
      target, OpenWFE::Extras::ArWorkitem.extract_keywords(h).join(' '))
  end
end

