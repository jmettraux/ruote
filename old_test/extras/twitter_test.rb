

require 'test/unit'

require 'openwfe/def'
require 'openwfe/workitem'
require 'openwfe/engine/engine'
require 'openwfe/extras/participants/twitterparticipants'


class TwitterTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  #
  # tests

  #def xxxx_0
  def test_0

    tp = OpenWFE::Extras::TwitterParticipant.new(
      "openwferu", ENV['OWFE_TWITTER_PASSWORD'], :no_ssl => true)

    wi = OpenWFE::InFlowWorkItem.new
    wi.twitter_message = "from #{self.class.name} #{Time.now.to_s}"
    tp.consume(wi)

    wi.twitter_message = "from #{self.class.name} #{Time.now.to_s} personal"
    wi.twitter_target = "jmettraux"
    tp.consume(wi)

    assert true
  end

  class TwitterDef < OpenWFE::ProcessDefinition
    twitter
  end

  def test_1

    engine = OpenWFE::Engine.new

    tp = OpenWFE::Extras::TwitterParticipant.new(
      "openwferu", ENV['OWFE_TWITTER_PASSWORD'], :no_ssl => true)

    engine.register_participant "twitter", tp

    li = OpenWFE::LaunchItem.new TwitterDef
    # no twitter message

    fei = engine.launch li

    engine.wait_for fei

    assert true
  end
end

