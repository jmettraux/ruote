
#
# Testing Ruote (OpenWFEru)
#
# Fri Jul 31 10:21:51 JST 2009
#

require 'socket' # just for SocketError

require File.join(File.dirname(__FILE__), 'base')


class FtProcessDefinitionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_sequence

    pdef = %{
<process-definition name="test">
  <sequence>
    <echo>a</echo>
    <echo>b</echo>
  </sequence>
</process-definition>
    }

    #noisy

    assert_trace(pdef, %w[ a b ])
  end

  def test_remote_definitions_not_allowed

    assert_raise ArgumentError do
      @engine.launch('http://defs.example.com/def0.rb')
    end
  end

  def test_remote_definitions_allowed

    @engine.context[:remote_definition_allowed] = true

    assert_raise SocketError do
      @engine.launch('http://defs.example.com/def0.rb')
    end
  end

  def test_json_definition

    require 'json'
    Ruote::Json.backend = Ruote::Json::JSON

    #pdef = Ruote.process_definition :name => 'test' do
    #  sequence do
    #    echo 'a'
    #    echo 'b'
    #  end
    #end
    #p pdef.to_json

    assert_trace(
      "[\"define\",{\"name\":\"test\"},[[\"sequence\",{},[[\"echo\",{\"a\":null},[]],[\"echo\",{\"b\":null},[]]]]]]",
      %w[ a b ])

    Ruote::Json.backend = Ruote::Json::NONE
      # back to initial state
  end

  def test_local_definition

    path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'pdef.xml'))

    assert_trace(path, %w[ a b ])
  end
end

