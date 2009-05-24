#
# Testing Ruote (OpenWFE) as nanite mapper
#
# Kenneth Kalmer (opensourcery.co.za)
#
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/extras/participants/nanite_mapper_participant'

class TestAgent
  include Nanite::Actor

  expose :echo, :bar

  def echo( payload )
    payload
  end

  def bar( payload )
    h = OpenWFE::Json.decode( payload )
    h['attributes']['foo'] = 'BAR'
    OpenWFE::Json.encode( h )
  end

  def decode( workitem )
    OpenWFE::Json.decode(workitem)
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
      :root => File.dirname(__FILE__) + '/../../tmp',
      :identity => "mapper-#{Time.now.to_i}"
    }
    begin
      tries ||= 1
      Timeout::timeout(10) {
        @nanite_mapper = OpenWFE::Extras::NaniteMapperParticipant.new( options )
      }
    rescue Timeout::Error
      if tries < 10
        puts 'Mapper failed to start, trying again'
        tries += 1
        retry
      else
        flunk "Couldn't start mapper"
      end
    end

    File.open( File.dirname(__FILE__) + '/../../tmp/init.rb', 'w+' ) do |f|
      f.write "register TestAgent.new"
    end
    
    @nanite_actor = Thread.new do
      options[ :user ] = 'nanite'
      options[ :actors ] = 'TestAgent'
      options[ :identity ] = 'agent-' + Time.now.to_i.to_s
      Nanite.start_agent( options )
    end

    sleep 5
  end

  def teardown
    super
    
    @nanite_actor.join
    
    begin
      File.delete( File.dirname(__FILE__) + '/../../tmp/init.rb' )
      File.delete( File.dirname(__FILE__) + '/../../tmp/config.yml' )
    rescue Errno::ENOENT
    end

    AMQP.stop { EM.stop }
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
        nanite :resource => '/test_agent/bar'
        _print '${f:foo}'
      end
    end
    EOF

    mapper = @engine.register_participant( :nanite, @nanite_mapper )

    fei = @engine.launch pdef
    wait fei
    assert_engine_clean

    assert_equal "BAR", @tracer.to_s

    purge_engine
  end
end
