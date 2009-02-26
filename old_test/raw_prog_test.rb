
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#


# ensure we don't load an installed gem
$:.unshift( File.dirname(__FILE__) + '/../lib' ) unless \
  $:.include?( File.dirname(__FILE__) + '/../lib' )

require 'rubygems'

require 'test/unit'
require 'openwfe/def'
require 'openwfe/expool/def_parser'


class RawProgTest < Test::Unit::TestCase

  XML_DEF = %(
<process-definition name='test0' revision='0'>
<sequence>
<participant ref='a'/>
<participant ref='b'/>
</sequence>
</process-definition>
  ).strip.gsub(/\n/, '')

  #
  # TEST 0
  #

  class TestDefinition < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test0", :revision => "0" do
        sequence do
          participant :ref => "a"
          participant :ref => "b"
        end
      end
    end
  end

  def test_prog_0

    s = OpenWFE::ExpressionTree.to_s(TestDefinition.new.make)

    assert_equal XML_DEF, s
  end

  def test_prog_0b

    #s = TestDefinition.do_make.to_s
    s = OpenWFE::ExpressionTree.to_s(TestDefinition.do_make)

    assert_equal XML_DEF, s
  end


  #
  # TEST 1
  #

  def test_prog_1

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

    assert XML_DEF, s
  end


  #
  # TEST 2
  #

  class TestDefinition2 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test2", :revision => "0" do
        sequence do
          set :field => "toto" do
            "nada"
          end
          participant :ref => "b"
        end
      end
    end
  end

  XML_DEF2 =
    "<process-definition name='test2' revision='0'>"+
    "<sequence>"+
    "<set field='toto'>"+
    "nada"+
    "</set>"+
    "<participant ref='b'/>"+
    "</sequence>"+
    "</process-definition>"

  def test_prog_2

    s = OpenWFE::ExpressionTree.to_s(TestDefinition2.do_make)

    assert_equal XML_DEF2, s

    #puts
    #puts TestDefinition2.do_make.to_code_s
  end


  #
  # TEST 3
  #

  class TestDefinition3 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test3", :revision => "0" do
        _if do
          equals :field_value => "nada", :other_value => "surf"
          participant :ref => "b"
        end
      end
    end
  end

  XML_DEF3 =
    "<process-definition name='test3' revision='0'>"+
    "<if>"+
    "<equals field-value='nada' other-value='surf'/>"+
    "<participant ref='b'/>"+
    "</if>"+
    "</process-definition>"

  CODE_DEF3 = """
process_definition :name => \"test3\", :revision => \"0\" do
  _if do
    equals :field_value => \"nada\", :other_value => \"surf\"
    participant :ref => \"b\"
  end
end""".strip

  def test_prog_3

    s = OpenWFE::ExpressionTree.to_s(TestDefinition3.do_make)

    assert_equal XML_DEF3, s

    assert_equal(
      CODE_DEF3,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition3.do_make))

    r = OpenWFE::DefParser.parse s

    assert_equal CODE_DEF3, OpenWFE::ExpressionTree.to_code_s(r)
  end


  #
  # TEST 4
  #

  class TestDefinition4 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test4", :revision => "0" do
        sequence do
          3.times { participant :ref => "b" }
        end
      end
    end
  end

  CODE_DEF4 = %{
process_definition :name => "test4", :revision => "0" do
  sequence do
    participant :ref => "b"
    participant :ref => "b"
    participant :ref => "b"
  end
end}.strip

  def test_prog_4

    #puts
    #puts TestDefinition4.do_make.to_s
    #puts
    #puts TestDefinition4.do_make.to_code_s

    assert_equal(
      CODE_DEF4,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition4.do_make))
  end


  #
  # TEST 4b
  #

  class TestDefinition4b < OpenWFE::ProcessDefinition
    def make
      sequence do
        [ :b, :b, :b ].each do |p|
          participant p
        end
      end
    end
  end

  CODE_DEF4b = %{
process_definition :name => "Test", :revision => "4b" do
  sequence do
    participant 'b'
    participant 'b'
    participant 'b'
  end
end}.strip

  def test_prog_4b

    assert_equal(
      CODE_DEF4b,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition4b.do_make))
  end


  #
  # TEST 5
  #

  class TestDefinition5 < OpenWFE::ProcessDefinition
    def make
      sequence do
        participant :ref => :toto
        sub0
      end
      process_definition :name => "sub0" do
        nada
      end
    end
  end

  CODE_DEF5 = %{
process_definition :name => "Test", :revision => "5" do
  sequence do
    participant :ref => :toto
    sub0
  end
  process_definition :name => "sub0" do
    nada
  end
end}.strip

  def test_prog_5

    assert_equal(
      CODE_DEF5,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition5.do_make))
  end


  #
  # TEST 6
  #

  class TestDefinition60 < OpenWFE::ProcessDefinition
    def make
      sequence do
        participant :ref => :toto
        nada
      end
    end
  end

  CODE_DEF6 = %{
process_definition :name => "Test", :revision => "60" do
  sequence do
    participant :ref => :toto
    nada
  end
end}.strip

  def test_prog_6

    assert_equal(
      CODE_DEF6,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition60.do_make))
  end


  #
  # TEST 7
  #

  class TestDefinitionSeven < OpenWFE::ProcessDefinition
    def make
      participant :ref => :toto
    end
  end

  CODE_DEF7 = %{
process_definition :name => "TestDefinitionSeven", :revision => "0" do
  participant :ref => :toto
end}.strip

  A_DEF7 = [
    "process-definition",
    { "name"=>"TestDefinitionSeven", "revision"=>"0" },
    [ [ "participant", { "ref" => :toto }, [] ] ]
  ]

  def test_prog_7

    assert_equal(
      CODE_DEF7,
      OpenWFE::ExpressionTree.to_code_s(TestDefinitionSeven.do_make))

    assert_equal(
      A_DEF7,
      TestDefinitionSeven.do_make)
  end

  #
  # TEST 8
  #

  def do_test (class_name, pdef)
    #
    # losing my time with an eval
    #
    result = eval """
      class #{class_name} < OpenWFE::ProcessDefinition
        def make
          participant 'nada'
        end
      end
      #{class_name}.do_make
    """
    assert_equal result[1]['name'], pdef[0]
    assert_equal result[1]['revision'], pdef[1]
  end

  def test_process_names

    do_test "MyProcessDefinition_10", ["MyProcess", "10"]
    do_test "MyProcessDefinition10", ["MyProcess", "10"]
    do_test "MyProcessDefinition1_0", ["MyProcess", "1.0"]
    do_test "MyProcessThing_1_0", ["MyProcessThing", "1.0"]
  end

  def do_test_2 (raw_name, expected)

    assert_equal(
      expected,
      OpenWFE::ProcessDefinition.extract_name_and_revision(raw_name))
  end

  def test_process_names_2

    do_test_2 'MyProcessDefinition_10', ['MyProcess', '10']
    do_test_2 'MyProcessDefinition5b', ['MyProcess', '5b']
  end


  #
  # TEST 9
  #

  JSON_DEF = <<-EOS
    ["process-definition",{"name":"mydef","revision":"0"},["alpha",{},[]]]
  EOS

  def test_9

    require 'json'
    assert_equal(
      ["process-definition", {"name"=>"mydef", "revision"=>"0"}, ["alpha", {}, []]],
      OpenWFE::DefParser.parse(JSON_DEF.strip))
  end

  YAML_DEF = "--- \n- process-definition\n- name: mydef\n  revision: \"0\"\n- - alpha\n  - {}\n\n  - []\n\n"

  def test_9b

    assert_equal(
      ["process-definition", {"name"=>"mydef", "revision"=>"0"}, ["alpha", {}, []]],
      OpenWFE::DefParser.parse(YAML_DEF))
  end

  #
  # TEST 10
  #

  class TestDefinition10 < OpenWFE::ProcessDefinition
    set_fields :value => { 'type' => 'horse' }
  end
  class TestDefinition10b < OpenWFE::ProcessDefinition
    set_fields do
      { 'type' => 'horse' }
    end
  end

  def test_10

    assert_equal(
      %{process_definition :name => "Test", :revision => "10" do
  set_fields :value => {"type"=>"horse"}
end},
      OpenWFE::ExpressionTree.to_code_s(TestDefinition10.do_make))

    assert_equal(
      %{<process-definition name='Test' revision='10'><set-fields><hash><entry><string>type</string><string>horse</string></entry></hash></set-fields></process-definition>},
      OpenWFE::ExpressionTree.to_xml(TestDefinition10.do_make).to_s)
  end

  def test_11

    assert_equal(
      "error 'sthing went wrong', :if => \"${f:surf}\"",
      OpenWFE::ExpressionTree.to_code_s(
        [ 'error', { 'if' => '${f:surf}' }, [ 'sthing went wrong' ] ]))
  end

end

