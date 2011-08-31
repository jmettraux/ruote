
#
# testing ruote
#
# Fri Jul 31 09:50:13 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/reader/xml'


class XmlReaderTest < Test::Unit::TestCase

  def test_sequence

    tree = Ruote::XmlReader.read(%{
<define name="nada">
  <sequence>
    <alpha/>
    <bravo/>
  </sequence>
</define>
    })

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
      ]],
      tree)
  end

  def test_echo

    tree = Ruote::XmlReader.read(%{
<process-definition name="nada">
  <echo>la vida loca</echo>
</process-definition>
    })

    assert_equal(
      ["process_definition", {"name"=>"nada"}, [["echo", {"la vida loca"=>nil}, []]]],
      tree)
  end

  def test_concurrent_iterator

    tree = Ruote::XmlReader.read(%{
<process-definition name="nada">
  <concurrent-iterator on-field="toti" to-field="toto">
  </concurrent-iterator>
</process-definition>
    })

    assert_equal(
      ["process_definition", {"name"=>"nada"}, [
        ["concurrent_iterator", {"on_field"=>"toti", "to_field"=>"toto"}, []]]],
      tree)
  end
end

