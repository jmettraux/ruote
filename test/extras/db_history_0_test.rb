
require 'test/unit'
require 'extras/active_connection'
require 'openwfe/engine'
require 'openwfe/extras/expool/dbhistory'


class DbHistory0Test < Test::Unit::TestCase

  def setup

    OpenWFE::Extras::HistoryEntry.destroy_all

    @engine = OpenWFE::Engine.new :definition_in_launchitem_allowed => true

    @engine.init_service "history", OpenWFE::Extras::DbHistory

    @engine.register_participant :alpha do
      # nothing
    end
    @engine.register_participant :bravo do
      # nothing
    end
  end

  def teardown

    @engine.stop

    #sleep 0.100
    #OpenWFE::Extras::HistoryEntry.destroy_all
  end

  def test_0

    @engine.launch <<-EOS
      class TDef < OpenWFE::ProcessDefinition
        sequence do
          alpha
          sub0
        end
        define sub0 do
          bravo
        end
      end
    EOS

    sleep 0.350

    hes = OpenWFE::Extras::HistoryEntry.find(:all)

    assert_equal 6, hes.size

    assert_equal 2, hes.select { |he| he.event == 'reply' }.size
    assert_equal 1, hes.collect { |he| he.wfid }.uniq.size
  end
end

