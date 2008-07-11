
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'test/unit'
require 'openwfe/def'
require 'openwfe/expool/parser'


class RawProgTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  XML_DEF =
    "<process-definition name='test0' revision='0'>"+
    "<sequence>"+
    "<participant ref='a'/>"+
    "<participant ref='b'/>"+
    "</sequence>"+
    "</process-definition>"

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
process_definition :name => 'test3', :revision => '0' do
  _if do
    equals :field_value => 'nada', :other_value => 'surf'
    participant :ref => 'b'
  end
end""".strip

  def test_prog_3

    s = OpenWFE::ExpressionTree.to_s(TestDefinition3.do_make)

    assert_equal XML_DEF3, s

    assert_equal(
      CODE_DEF3,
      OpenWFE::ExpressionTree.to_code_s(TestDefinition3.do_make))

    #r = OpenWFE::SimpleExpRepresentation.from_xml(s)
    r = OpenWFE::DefParser.parse_xml s

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

  CODE_DEF4 = """
process_definition :name => 'test4', :revision => '0' do
  sequence do
    participant :ref => 'b'
    participant :ref => 'b'
    participant :ref => 'b'
  end
end""".strip

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

  CODE_DEF4b = """
process_definition :name => 'Test', :revision => '4b' do
  sequence do
    participant do
      'b'
    end
    participant do
      'b'
    end
    participant do
      'b'
    end
  end
end""".strip

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

  CODE_DEF5 = """
process_definition :name => 'Test', :revision => '5' do
  sequence do
    participant :ref => :toto
    sub0
  end
  process_definition :name => 'sub0' do
    nada
  end
end""".strip

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

  CODE_DEF6 = """
process_definition :name => 'Test', :revision => '60' do
  sequence do
    participant :ref => :toto
    nada
  end
end""".strip

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

  CODE_DEF7 = """
process_definition :name => 'TestDefinitionSeven', :revision => '0' do
  participant :ref => :toto
end""".strip

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

    do_test_2 "MyProcessDefinition_10", ["MyProcess", "10"]
    do_test_2 "MyProcessDefinition5b", ["MyProcess", "5b"]
  end


  #
  # TEST 9
  #

  class TestDefinition9 < OpenWFE::ProcessDefinition
    def make
      description "this is my process"
      sequence do
        participant :ref => :toto
      end
    end
  end

  CODE_DEF9 = """
process_definition :name => 'Test', :revision => '60' do
  description 'this is my process'
  sequence do
    participant :ref => 'toto'
    nada
  end
end""".strip

  def _test_prog_9

    assert CODE_DEF9, TestDefinition9.do_make.to_code_s
  end

end

