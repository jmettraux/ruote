
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require 'rubygems'

require 'test/unit'

require 'openwfe/engine/engine'
require 'openwfe/participants/participants'

#
# testing misc things
#

class ParticipantTest < Test::Unit::TestCase

  def setup
    @engine = OpenWFE::Engine.new
  end

  def teardown
    @engine.stop
  end

  def test_lookup_participant

    @engine.register_participant :toto, OpenWFE::NullParticipant

    p = @engine.get_participant "toto"
    assert_kind_of OpenWFE::NullParticipant, p

    p = @engine.get_participant :toto
    assert_kind_of OpenWFE::NullParticipant, p

    assert_equal 1, @engine.get_participant_map.size
  end

  def test_unregister_participant

    assert ( ! @engine.unregister_participant(:nada))

    @engine.register_participant :toto, OpenWFE::NullParticipant

    assert_equal 1, @engine.get_participant_map.size

    assert @engine.unregister_participant(:toto)

    assert_equal 0, @engine.get_participant_map.size

    @engine.register_participant "user_.*", OpenWFE::NullParticipant

    assert_equal 1, @engine.get_participant_map.size

    assert @engine.unregister_participant("user_.*")

    assert_equal 0, @engine.get_participant_map.size
  end

  def test_order

    s = ""

    @engine.register_participant "a.*", :astar
    @engine.register_participant "alpha", :alpha

    assert_equal :astar, @engine.get_participant("alpha")

    clean_participants

    @engine.register_participant "alpha", :alpha
    @engine.register_participant "a.*", :astar

    assert_equal :alpha, @engine.get_participant("alpha")

    clean_participants

    @engine.register_participant "a.*", :astar

    assert_equal :astar, @engine.get_participant("alpha")

    @engine.register_participant "alpha", { :participant => :alpha, :position => :first }

    assert_equal :alpha, @engine.get_participant("alpha")
    assert_equal :astar, @engine.get_participant("abricot")
  end

  protected

    def clean_participants

      @engine.get_participant_map.instance_variable_set(
        :@participants, [])
    end

end
