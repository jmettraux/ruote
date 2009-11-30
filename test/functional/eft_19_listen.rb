
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Mar 12 12:45:07 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftListenTest < Test::Unit::TestCase
  include FunctionalBase

  def test_listen

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do

        listen :to => '^channel_.$' do
          sequence do
            set :field => 'pparams', :field_value => 'params'
            participant :ref => 'alpha'
          end
        end

        sequence do

          wait '500'
            #
            # just making sure that the participant is evaluated
            # after the listen [registration]

          set :field => 'drink', :value => 'tequila'

          participant :ref => 'channel_z', :navi => 'gps'
        end
      end
    end

    @engine.register_participant 'channel_z', OpenWFE::NoOperationParticipant

    @engine.register_participant 'alpha' do |workitem|
      @tracer << workitem['drink']
      @tracer << ':'
      @tracer << workitem['pparams']['navi']
    end

    assert_trace pdef, 'tequila:gps'
  end
end

