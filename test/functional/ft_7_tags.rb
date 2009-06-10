
#
# Testing Ruote (OpenWFEru)
#
# Wed Jun 10 11:03:26 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtTagsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_tag

    pdef = Ruote.process_definition do
      sequence :tag => 'main' do
        alpha :tag => 'part'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::JoinableHashParticipant

    noisy

    wfid = @engine.launch(pdef)
    alpha.join

    ps = @engine.process_status(wfid)

    #p ps.variables
    #ps.expressions.each { |e| p [ e.fei, e.variables ] }
    assert_equal '0_0', ps.variables['main'].expid
    assert_equal '0_0_0', ps.variables['part'].expid

    assert_equal 2, logger.log.select { |e| e[1] == :entered_tag }.size

    alpha.reply(alpha.first)
    wait_for(wfid)

    assert_equal 2, logger.log.select { |e| e[1] == :left_tag }.size
  end
end

