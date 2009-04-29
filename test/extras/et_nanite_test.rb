#
# Testing Ruote (OpenWFE) as nanite mapper
#
# Kenneth Kalmer (opensourcery.co.za)
#
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/extras/participants/nanite_mapper_participant'
require 'json'

class TestAgent
  include Nanite::Actor

  expose :echo, :bar

  def echo( payload )
    payload
  end

  def bar( payload )
    h = JSON.parse( payload )
    h['attributes']['bar'] = 'BAR'
    h.to_json
  end

  def decode( workitem )
    defined?(ActiveSupport::JSON) ? ActiveSupport::JSON.decode(workitem) : JSON.parse(workitem)
  end
end

class EtNaniteTest < Test::Unit::TestCase
  include FunctionalBase

  def setup
    super

    log_level_to_debug

    options = {
      :host => 'localhost',
      :user => 'mapper',
      :pass => 'testing',
      :vhost => '/nanite',
      :log_level => 'debug',
      :root => File.dirname(__FILE__) + '/../../tmp'
    }
    @nanite_mapper = OpenWFE::Extras::NaniteMapperParticipant.new( options )

    File.open( File.dirname(__FILE__) + '/../../tmp/init.rb', 'w+' ) do |f|
      f.write "register TestAgent.new"
    end
    
    @nanite_actor = Thread.new do
      options[ :user ] = 'nanite'
      options[ :actors ] = 'TestAgent'
      options[ :identity ] = 'test-agent'
      EM.run do
        Nanite.start_agent( options )
      end
    end

    sleep 16
  end

  def teardown
    puts 't1'
    AMQP.stop
    EM.stop
    puts 't2'
    @nanite_mapper.stop
    puts 't3'
    @nanite_actor.exit
    puts 't4'
    super
  end
  
  def test_nanite_mapper_simple
    pdef = <<-EOF
    class NaniteMapperProcess0 < OpenWFE::ProcessDefinition
      sequence do
        nanite :resource => '/test_agent/bar'
        _print 'done.'
      end
    end
    EOF

    mapper = @engine.register_participant( :nanite, @nanite_mapper )

    assert_trace( pdef, 'done.' )
  end

  def test_nanite_agent_attributes
    pdef = <<-EOF
    class NaniteMapperProcess0 < OpenWFE::ProcessDefinition
      sequence do
        nanite :resource => '/test_agent/echo'
        _print '${f:bar}'
      end
    end
    EOF

    mapper = @engine.register_participant( :nanite, @nanite_mapper )

    assert_trace( pdef, 'BAR' )
  end
end
