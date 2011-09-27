
#
# testing ruote
#
# Fri Jul 31 10:21:51 JST 2009
#

require 'socket' # just for SocketError

require File.expand_path('../base', __FILE__)


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

    assert_trace(%w[ a b ], pdef)
  end

  def test_remote_definitions_not_allowed

    assert_raise ArgumentError do
      @dashboard.launch('http://defs.example.com/def0.rb')
    end
  end

  def test_remote_definitions_allowed

    @dashboard.context['remote_definition_allowed'] = true

    e = assert_raise SocketError, OpenURI::HTTPError, ArgumentError do
      @dashboard.launch('http://defs.example.com/def0.rb')
    end

    assert_not_equal 'remote process definitions are not allowed', e.message
  end

  def test_json_definition

    prev = Rufus::Json.backend

    require 'json' # warning, json 1.4.3 is buggy...
    #require 'json/pure'
    Rufus::Json.backend = :json

    #pdef = Ruote.process_definition :name => 'test' do
    #  sequence do
    #    echo 'a'
    #    echo 'b'
    #  end
    #end
    #p pdef.to_json

    assert_trace(
      %w[ a b ],
      "[\"define\",{\"name\":\"test\"},[[\"sequence\",{},[[\"echo\",{\"a\":null},[]],[\"echo\",{\"b\":null},[]]]]]]")

    Rufus::Json.backend = prev
      # back to initial state
  rescue => e
    p e
  end

  def test_local_definition

    path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'pdef.xml'))

    assert_trace(%w[ a b ], path)
  end

  def test_local_unexpanded_definition

    path = File.join(File.dirname(__FILE__), '..', 'pdef.xml')

    assert_trace(%w[ a b ], path)
  end
end

