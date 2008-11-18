
require 'test/unit'

require 'extras/active_connection'

require 'openwfe/def'
require 'openwfe/workitem'
require 'openwfe/flowexpressionid'
require 'openwfe/engine/engine'
require 'openwfe/participants/participant'

require 'openwfe/extras/participants/activeparticipants'

#Thread.abort_on_exception = true


class WithEngineTest < Test::Unit::TestCase

  def setup

    #ExtrasTables.down; exit 0
    #ExtrasTables.up; exit 0

    OpenWFE::Extras::Workitem.delete_all
    OpenWFE::Extras::Field.delete_all

    @engine = OpenWFE::Engine.new :definition_in_launchitem_allowed => true
    #require 'openwfe/engine/file_persisted_engine'
    #@engine = OpenWFE::FilePersistedEngine.new

    @engine.register_participant(
      :active0, OpenWFE::Extras::ActiveParticipant)
    @engine.register_participant(
      :active1, OpenWFE::Extras::ActiveParticipant)
  end

  def teardown
    $OWFE_LOG.level = Logger::INFO
  end

  #
  # tests

  class MyDefinition < OpenWFE::ProcessDefinition
    sequence do
      active0
      active1
    end
  end

  def test_0

    $OWFE_LOG.level = Logger::DEBUG

    li = OpenWFE::LaunchItem.new MyDefinition
    li.customer_name = 'toto'
    fei = @engine.launch li

    sleep 1

    #puts @engine.get_expression_storage.to_s
    #p @engine.get_error_journal.get_error_logs

    wi = OpenWFE::Extras::Workitem.find_by_participant_name "active0"

    assert_not_nil wi

    wi.fields << OpenWFE::Extras::Field.new_field("active0", "was here")
    wi.fields << OpenWFE::Extras::Field.new_field("active1", [ 1, 2, 4 ])

    @engine.get_participant(:active0).reply_to_engine(wi)

    sleep 1

    wi = OpenWFE::Extras::Workitem.find_by_participant_name("active1")

    assert_not_nil wi
    assert_not_nil wi.expid

    f = OpenWFE::Extras::Field.find_by_svalue "was here"

    assert_not_nil f
    assert_equal wi, f.workitem

    f = OpenWFE::Extras::Field.find_by_fkey "active1"

    assert_equal f.value, [ 1, 2, 4 ]

    #$OWFE_LOG.level = Logger::DEBUG

    @engine.cancel_expression wi.as_owfe_workitem.fei
      #
      # directly cancelling the *ParticipantExpression*

    sleep 1

    wi = OpenWFE::Extras::Workitem.find_by_participant_name("active1")

    assert_nil wi

    #$OWFE_LOG.level = Logger::INFO
  end

  #
  # Testing the Workitem.reply(engine) method.
  #
  def test_1

    li = OpenWFE::LaunchItem.new(MyDefinition)
    li.customer_name = 'toto'
    @engine.launch li

    sleep 1

    wi = OpenWFE::Extras::Workitem.find_by_participant_name("active0")

    assert_not_nil wi.dispatch_time

    wi.reply @engine

    sleep 0.5

    wi = OpenWFE::Extras::Workitem.find_by_participant_name("active1")

    #wi.reply(@engine)
    @engine.reply(wi)
      #
      # loading the 'active participants' now retrofits the engine
      # to accept 'active workitems'

    sleep 0.5

    wi = OpenWFE::Extras::Workitem.find_by_participant_name("active0")
    assert_nil wi

    wi = OpenWFE::Extras::Workitem.find_by_participant_name("active1")
    assert_nil wi
  end

end

