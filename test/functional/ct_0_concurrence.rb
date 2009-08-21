
#
# Testing Ruote (OpenWFEru)
#
# Wed Jul  8 15:30:55 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class CtConcurrenceTest < Test::Unit::TestCase
  include FunctionalBase

  class Ruote::HashParticipant
    # removes first available workitem from hash
    def pop
      @items.delete(@items.keys.first)
    end
  end

  def setup

    @tracer = Tracer.new

    @engine0 = start_new_engine
    @engine1 = start_new_engine

    change_concurrence_expression
  end

  def teardown

    #@engine0.storage.purge if @engine0.storage.respond_to?(:purge)
    #@engine1.storage.purge if @engine1.storage.respond_to?(:purge)

    @engine0.shutdown
    @engine1.shutdown

    FileUtils.rm_rf('work')

    unchange_concurrence_expression
      # play nice with other tests
  end

  def test_no_collision

    pdef = Ruote.process_definition do
      concurrence do
        alpha
        alpha
      end
    end

    alpha0 = @engine0.register_participant :alpha, Ruote::HashParticipant
    alpha1 = @engine1.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine0.launch(pdef)

    sleep 0.200

    assert_not_nil @engine0.process(wfid)
    assert_not_nil @engine0.process(wfid)

    assert_equal 2, alpha0.size
    assert_equal 0, alpha1.size

    @engine1.reply(alpha0.pop)
    sleep 0.300
    @engine0.reply(alpha0.pop)
    sleep 0.300

    assert_equal nil, @engine0.process(wfid)
    assert_equal nil, @engine1.process(wfid)
  end

  def test_collision

    pdef = Ruote.process_definition do
      concurrence do
        alpha
        alpha
      end
    end

    alpha0 = @engine0.register_participant :alpha, Ruote::HashParticipant
    alpha1 = @engine1.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine0.launch(pdef)

    sleep 0.300

    @engine1.reply(alpha0.pop)
      # and immediately...
    @engine0.reply(alpha0.pop)

    sleep 0.300

    assert_nil @engine0.process(wfid)
    assert_nil @engine1.process(wfid)

    #puts `tree work/`
  end

  protected

  def start_new_engine

    ac = {}

    ac[:s_tracer] = @tracer
    #ac[:ruby_eval_allowed] = true
    #ac[:definition_in_launchitem_allowed] = true

    #ac[:engine_id] = engine_id
      # not relevant for multiple instances of the 'same' engine

    ac[:no_expstorage_cache] = true
      # !! very important for the 2 engines to share the same storage

    #ac[:noisy] = true

    engine_class = determine_engine_class(ac)
    engine_class = Ruote::FsPersistedEngine if engine_class == Ruote::Engine
    engine = engine_class.new(ac)

    engine.add_service(:s_logger, Ruote::TestLogger)

    engine
  end

  def change_concurrence_expression

    Ruote::Exp::ConcurrenceExpression.module_eval do
      alias :original_persist :persist
      def persist (probe=false)
        sleep 0.010
        original_persist(probe)
      end
    end
  end

  def unchange_concurrence_expression

    Ruote::Exp::ConcurrenceExpression.module_eval do
      alias :persist :original_persist
    end
  end
end

