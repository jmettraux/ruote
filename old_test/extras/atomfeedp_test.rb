#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 15:41:44 JST 2006
#
# Kita Yokohama
#

require 'test/unit'

require 'rubygems'

require 'openwfe/workitem'
require 'openwfe/engine/engine'
require 'openwfe/def'

require 'openwfe/extras/participants/atomfeed_participants'

require 'test/flowtestbase'


class AtomFeedParticipantTest < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # test atom 0

  class AtomDefinition0 < OpenWFE::ProcessDefinition
    sequence do

      set \
        :field => "atom_entry_title",
        :value => "#{$run_index}"
      set \
        :field => "colour",
        :value => "blue"
      participant :ref => "feed0-alpha"

      set \
        :field => "atom_entry_title",
        :value => "#{$run_index}"
      set \
        :field => "colour",
        :value => "red"
      participant :ref => "feed1-bravo"
    end
  end

  def test_atom_0

    feed0 = OpenWFE::Extras::AtomFeedParticipant.new(
      7,
"""
<p>
  <h1>${f:colour}</h1>
</p>
""")


    feed1 = OpenWFE::Extras::AtomFeedParticipant.new(7) do |fe, participant, workitem|

      t = Time.now.to_s
"""
<p>
  <h1>${f:colour}</h1>
  <ul>
    <li>flowexpression :   #{fe.fei.to_s}</li>
    <li>participant class :  #{participant.class}</li>
    <li>workitem att count : #{workitem.attributes.length}</li>
    <li>now :        #{t}</li>
    <li>entry title :    ${f:atom_entry_title}</li>
  </ul>
</p>
"""
    end

    @engine.register_participant "feed0-.*", feed0
    @engine.register_participant "feed1-.*", feed1

    $run_index = "first run"
    @engine.launch(OpenWFE::LaunchItem.new(AtomDefinition0))

    $run_index = "second run"
    @engine.launch(OpenWFE::LaunchItem.new(AtomDefinition0))

    $run_index = "third and last run"
    @engine.launch(OpenWFE::LaunchItem.new(AtomDefinition0))

    @engine.join_until_idle

    assert File.exist?('work/atom_feed0-alpha.xml')
    assert File.exist?('work/atom_feed1-bravo.xml')

    assert_equal(
      3,
      OpenWFE.grep(
        "workitem att count", "work/atom_feed1-bravo.xml").size)
    assert_equal(
      3,
      OpenWFE.grep(
        "<h1>red</h1>", "work/atom_feed1-bravo.xml").size)
  end

end

