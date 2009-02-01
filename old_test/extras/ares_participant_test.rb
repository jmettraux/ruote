
#
# testing the ActiveResourceParticipant by Torsten Schoenebaum
#
# Tue Dec 16 09:01:28 JST 2008
#

require 'test/unit'

$:.unshift(File.dirname(__FILE__) + '/../../lib') unless \
  $:.include?(File.dirname(__FILE__) + '/../../lib')

require 'rubygems'
#require 'mocha'

require 'openwfe/extras/participants/active_resource_participants'
require 'active_resource/http_mock'


class AresParticipantTest < Test::Unit::TestCase

  def setup

    @engine = Engine.new

    @fruit1 = { 'id' => 1, 'name' => 'apple' }
    @fruits = [ @fruit1 ]

    ActiveResource::HttpMock.respond_to do |mck|
      mck.get '/fruits/.xml', {}, @fruits.to_xml(:root => 'fruits')
      mck.get '/fruits/1/.xml', {}, @fruit1.to_xml(:root => 'fruit')
        #
        # why /.xml ??, well... it's just some mocking after all...
        # no time to dig deeper
    end
  end

  def test_0

    response = nil

    par = new_ares_participant({
      :resource_name => 'fruit',
      :response_handling => lambda { |r, wi| response = r }
    })

    workitem = new_workitem(:resource_id => 1)

    par.consume(workitem)

    assert_equal(@fruit1, response)
    assert_equal({'params'=>{:resource_id=>1}}, @engine.workitem)
  end

  protected

    class Engine
      attr_accessor :workitem
      def reply (wi)
        @workitem = wi
      end
    end

    def new_workitem (opts={})
      wi = { 'params' => opts }
      def wi.params
        self['params'] ||= {}
      end
      wi
    end

    def new_ares_participant(opts={})

      par = OpenWFE::Extras::ActiveResourceParticipant.new(opts)

      par.instance_variable_set(:@engine, @engine)
      def par.get_engine
        @engine
      end

      par
    end
end

