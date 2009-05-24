
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/def'
require 'openwfe/expool/def_parser'


class ParserRubyTest < Test::Unit::TestCase

  XML_0 = %(
<process-definition name='test0' revision='0'>
<sequence>
<participant ref='a'/>
<participant ref='b'/>
</sequence>
</process-definition>
  ).strip.gsub(/\n/, '')

  class TestDefinition < OpenWFE::ProcessDefinition
    def make
      process_definition :name => 'test0', :revision => '0' do
        sequence do
          participant :ref => 'a'
          participant :ref => 'b'
        end
      end
    end
  end

  def test_0

    s = OpenWFE::ExpressionTree.to_s(TestDefinition.new.make)

    assert_equal XML_0, s
  end

  def test_1

    #s = TestDefinition.do_make.to_s
    s = OpenWFE::ExpressionTree.to_s(TestDefinition.do_make)

    assert_equal XML_0, s
  end

  def test_2

    pg = OpenWFE::ProcessDefinition.new

    class << pg
      def my_proc
        process_definition :name => "test0", :revision => "0" do
          sequence do
            participant :ref => "a"
            participant :ref => "b"
          end
        end
      end
    end
    pdef = pg.my_proc
    s = pdef.to_s

    assert XML_0, s
  end

  class TestDefinition3 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => 'test2', :revision => '0' do
        sequence do
          set :field => 'toto' do
            'nada'
          end
          participant :ref => 'b'
        end
      end
    end
  end

  XML_3 = %{
<process-definition name='test2' revision='0'>
<sequence>
<set field='toto'>
nada
</set>
<participant ref='b'/>
</sequence>
</process-definition>
  }.strip.gsub(/\n/, '')

  def test_3

    s = OpenWFE::ExpressionTree.to_s(TestDefinition3.do_make)

    assert_equal XML_3, s

    #puts
    #puts TestDefinition2.do_make.to_code_s
  end

  class TestDefinition4 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test4", :revision => "0" do
        _if do
          equals :field_value => "nada", :other_value => "surf"
          participant :ref => "b"
        end
      end
    end
  end

  XML_4 =
    "<process-definition name='test4' revision='0'>"+
    "<if>"+
    "<equals field-value='nada' other-value='surf'/>"+
    "<participant ref='b'/>"+
    "</if>"+
    "</process-definition>"

  CODE_4 = %{
process_definition :name => "test4", :revision => "0" do
  _if do
    equals :field_value => "nada", :other_value => "surf"
    participant :ref => "b"
  end
end
  }.strip

  def test_4

    s = OpenWFE::ExpressionTree.to_s(TestDefinition4.do_make)

    assert_equal(XML_4, s)

    assert_equal(
      CODE_4,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition4.do_make))

    r = OpenWFE::DefParser.parse(s)

    assert_equal(CODE_4, OpenWFE::ExpressionTree.to_code_s(r))
  end

  class TestDefinition5 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => 'test5', :revision => '0' do
        sequence do
          3.times { participant :ref => 'b' }
        end
      end
    end
  end

  CODE_5 = %{
process_definition :name => "test5", :revision => "0" do
  sequence do
    participant :ref => "b"
    participant :ref => "b"
    participant :ref => "b"
  end
end}.strip

  def test_5

    assert_equal(
      CODE_5,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition5.do_make))
  end

  class TestDefinition6 < OpenWFE::ProcessDefinition
    def make
      sequence do
        [ :b, :b, :b ].each do |p|
          participant p
        end
      end
    end
  end

  CODE_6 = %{
process_definition :name => "Test", :revision => "6" do
  sequence do
    participant 'b'
    participant 'b'
    participant 'b'
  end
end
  }.strip

  def test_6

    assert_equal(
      CODE_6,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition6.do_make))
  end

  class TestDefinition7 < OpenWFE::ProcessDefinition
    def make
      sequence do
        participant :ref => :toto
        sub0
      end
      process_definition :name => 'sub0' do
        nada
      end
    end
  end

  CODE_7 = %{
process_definition :name => "Test", :revision => "7" do
  sequence do
    participant :ref => :toto
    sub0
  end
  process_definition :name => "sub0" do
    nada
  end
end
  }.strip

  def test_7

    assert_equal(
      CODE_7,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition7.do_make))
  end

  class TestDefinition8 < OpenWFE::ProcessDefinition
    def make
      sequence do
        participant :ref => :toto
        nada
      end
    end
  end

  CODE_8 = %{
process_definition :name => "Test", :revision => "8" do
  sequence do
    participant :ref => :toto
    nada
  end
end
  }.strip

  def test_8

    assert_equal(
      CODE_8,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition8.do_make))
  end

  class TestDefinition9 < OpenWFE::ProcessDefinition
    def make
      participant :ref => :toto
    end
  end

  CODE_9 = %{
process_definition :name => "Test", :revision => "9" do
  participant :ref => :toto
end
  }.strip

  TREE_9 = [
    'process-definition',
    { 'name'=>'Test', 'revision'=>'9' },
    [ [ 'participant', { 'ref' => :toto }, [] ] ]
  ]

  def test_9

    assert_equal(
      CODE_9,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition9.do_make))

    assert_equal(
      TREE_9,
      TestDefinition9.do_make)
  end

  JSON_10 = %{
    ["process-definition",{"name":"mydef","revision":"0"},["alpha",{},[]]]
  }.strip

  def test_10

    require 'openwfe/util/json'

    assert_equal(
      ["process-definition", {"name"=>"mydef", "revision"=>"0"}, ["alpha", {}, []]],
      OpenWFE::DefParser.parse(JSON_10))
  end

  YAML_11 = "--- \n- process-definition\n- name: mydef\n  revision: \"0\"\n- - alpha\n  - {}\n\n  - []\n\n"

  def test_11

    assert_equal(
      ["process-definition", {"name"=>"mydef", "revision"=>"0"}, ["alpha", {}, []]],
      OpenWFE::DefParser.parse(YAML_11))
  end

  class TestDefinition12 < OpenWFE::ProcessDefinition
    set_fields :value => { 'type' => 'horse' }
  end

  #class TestDefinition12b < OpenWFE::ProcessDefinition
  #  set_fields do
  #    { 'type' => 'horse' }
  #  end
  #end
    #
    # TODO : wire me back in

  def test_12

    assert_equal(
      %{process_definition :name => "Test", :revision => "12" do
  set_fields :value => {"type"=>"horse"}
end},
      OpenWFE::ExpressionTree.to_code_s(TestDefinition12.do_make))

    assert_equal(
      %{<process-definition name='Test' revision='12'><set-fields><hash><entry><string>type</string><string>horse</string></entry></hash></set-fields></process-definition>},
      OpenWFE::ExpressionTree.to_xml(TestDefinition12.do_make).to_s)
  end

  def test_13

    assert_equal(
      "error 'sthing went wrong', :if => \"${f:surf}\"",
      OpenWFE::ExpressionTree.to_code_s(
        [ 'error', { 'if' => '${f:surf}' }, [ 'sthing went wrong' ] ]))
  end

end

