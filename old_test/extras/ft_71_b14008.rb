
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Thu Sep 13 09:50:29 JST 2007
#

require File.dirname(__FILE__) + '/../flowtestbase'
require 'openwfe/def'
require 'openwfe/extras/participants/active_participants'
require 'extras/active_connection'


class FlowTest71 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Travel < OpenWFE::ProcessDefinition

    set :v => 'manager',   :value => 'alpha'
    set :v => 'budget',  :value => 'bravo'
    set :v => 'todo',    :value => 'bravo'

    set :f => 'type',    :value => 'travel'
    set :f => 'request_id', :value => '1234'

    sequence do
      concurrence do
        manager
        budget
      end
      todo
    end
  end

  def test_0

    #log_level_to_debug

    @engine.register_participant '.*' do |wi|
      assert_equal wi.attributes['type'], 'travel'
      assert_equal wi.attributes['request_id'], '1234'
    end

    fei = nil
    30.times do
      fei = @engine.launch(Travel)
    end

    sleep 0.500
  end

  def test_1

    #log_level_to_debug

    OpenWFE::Extras::Workitem.delete(:all)

    @engine.register_participant '.*', OpenWFE::Extras::ActiveParticipant

    fei = nil
    50.times do
      fei = @engine.launch(Travel)
      sleep 0.200

      wi = OpenWFE::Extras::Workitem.find_by_participant_name('alpha')
      assert_equal wi.field('type').svalue, 'travel'
      assert_equal wi.field('request_id').svalue, '1234'

      OpenWFE::Extras::Workitem.delete(:all)
    end
  end

end

