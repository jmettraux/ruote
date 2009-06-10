
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
        nemo :tag => 'part'
      end
    end

    nemo = @engine.register_participant :nemo, Ruote::JoinableHashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    nemo.join

    ps = @engine.process_status(wfid)

    #p ps.variables
    #ps.expressions.each { |e| p [ e.fei, e.variables ] }
    assert_equal '0_0', ps.variables['main'].expid
    assert_equal '0_0_0', ps.variables['part'].expid

    #assert_equal 1, logger.log.select { |e| e[1] == :on_error }.size
  end
end

