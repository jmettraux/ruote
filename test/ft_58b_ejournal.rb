
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Thu Jun 12 08:38:02 JST 2008
#

require 'rubygems'

require 'openwfe/def'

require 'flowtestbase'

require 'openwfe/engine/file_persisted_engine'
require 'openwfe/expool/errorjournal'
require 'openwfe/representations'



class FlowTest58 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      participant :alpha
      participant :bravo
    end
  end

  def test_0

    ejournal = @engine.get_error_journal

    @engine.register_participant(:alpha) do |wi|
      raise "error inside of block participant"
    end

    fei = launch Test0

    sleep 0.350

    assert File.exist?("work/ejournal/#{fei.parent_wfid}.ejournal") \
      if @engine.is_a?(OpenWFE::FilePersistedEngine)

    errors = ejournal.get_error_log fei

    assert_equal 1, errors.length
    assert_equal 'RuntimeError', errors.first.error_class

    assert_equal(
      'error inside of block participant',
      errors.first.stacktrace.split("\n").first)

    @engine.replay_at_error errors.first

    sleep 0.350

    errors = ejournal.get_error_log fei

    assert_equal 1, errors.length
    assert_equal 'RuntimeError', errors.first.error_class

    assert_equal(
      'error inside of block participant',
      errors.first.stacktrace.split("\n").first)

    purge_engine
  end

  #
  # checking to_xml and to_json
  #
  def test_1

    ejournal = @engine.get_error_journal

    @engine.register_participant(:alpha) do |wi|
      raise 'something went wrong Major Tom'
    end

    fei = launch Test0

    sleep 0.350

    ps = @engine.process_status(fei)

    xml = OpenWFE::Xml.process_to_xml(ps, :indent => 2, :linkgen => :plain)
    #puts xml
    xml = REXML::Document.new(xml)

    assert_equal(
      'something went wrong Major Tom', xml.root.elements['//message'].text)

    h = OpenWFE::Json.process_to_h(ps, :linkgen => :plain)
    #puts h.inspect

    errs = h['errors']

    assert_equal 2, errs.size
    assert_equal 1, errs['elements'].size

    assert_equal(
      'something went wrong Major Tom', errs['elements'].first['message'])

    purge_engine
  end

end

