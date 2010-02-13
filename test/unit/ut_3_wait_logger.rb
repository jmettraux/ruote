
#
# testing ruote
#
# Thu Dec 10 14:08:30 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/parser/ruby_dsl'
require 'ruote/engine'
require 'ruote/worker'
require 'ruote/storage/hash_storage'
require 'ruote/part/hash_participant'


class UtWaitLoggerTest < Test::Unit::TestCase

  def test_wait_for_participant

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        #wait '1'
        alpha
      end
    end

    engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))

    #engine.context.logger.noisy = true

    alpha = engine.register_participant :alpha, Ruote::HashParticipant.new

    engine.launch(pdef)
    msg = engine.wait_for(:alpha)

    assert_equal 1, alpha.size

    assert_not_nil msg
    assert_not_nil msg['workitem']
  end
end

