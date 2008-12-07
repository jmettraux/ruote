
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'rubygems'

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest11 < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #

  class TestDefinition0 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test0", :revision => "0" do
        sequence do
          _print do "a" end
          _print { "b" }
          _print "c"
            #
            # all these notations for nesting a string
            # are allowed
            #
            # of course, the latter one is the nicest
        end
      end
    end
  end

  def test_0

    #log_level_to_debug

    dotest TestDefinition0, "a\nb\nc"
  end


  #
  # Test 1
  #

  class TestDefinition1 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test1", :revision => "0" do
        sequence do
          set :variable => "toto", :value => "nada"
          _print "toto:${toto}"
          set :field => "ftoto" do
            "_${toto}__${r:'123'.reverse}"
          end
          _print { "ftoto:${f:ftoto}" }
        end
      end
    end
  end

  def test_1

    dotest(
      TestDefinition1,
      """
toto:nada
ftoto:_nada__321
      """.strip,
      true)
  end


  #
  # Test 2
  #

  class TestDefinition2 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test2", :revision => "0" do
        sequence do
          set :variable => "toto", :value => "nada"
          _if do
            equals :variable_value => "toto", :other_value => "nada"
            _print "toto:${toto}"
            _print "not ok"
          end
        end
      end
    end
  end

  def test_2

    dotest(
      TestDefinition2,
      "toto:nada")
      #true)
  end


  #
  # Test 3
  #

  class TestDefinition3 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test3", :revision => "0" do
        sequence do
          subprocess :ref => "sub0", :var0 => "a"
          sub0 :var0 => "b"
        end
        process_definition :name => "sub0" do
          _print "var0 is '${var0}'"
        end
      end
    end
  end

  def test_3

    #puts
    #puts TestDefinition3.do_make(ExpressionMap.new(nil, nil)).to_code_s
    #puts
    #puts TestDefinition3.do_make(ExpressionMap.new(nil, nil)).to_s

    dotest TestDefinition3, "var0 is 'a'\nvar0 is 'b'"
  end


  #
  # Test 4
  #

  class TestDefinition4 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test4", :revision => "0" do
        sequence do
          sequence do
            _print "a"
          end
          sequence do
            _print "b"
          end
        end
      end
    end
  end

  CODE4 = """
process_definition :name => \"test4\", :revision => \"0\" do
  sequence do
    sequence do
      _print 'a'
    end
    sequence do
      _print 'b'
    end
  end
end
  """.strip

  def test_4

    s = OpenWFE::ExpressionTree.to_code_s TestDefinition4.do_make

    dotest(
      TestDefinition4,
      "a\nb")
      #0.300)

    assert_equal CODE4, s, "nested sequences test failed (4)"
  end


  #
  # Test 5
  #

  class TestDefinition5 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test5", :revision => "0" do
        sequence do
          sequence do
            _print { "a" }
          end
          sequence do
            _print { "b" }
          end
        end
      end
    end
  end

  CODE5 = <<-EOS
process_definition :name => 'test5', :revision => '0' do
  sequence do
    sequence do
      _print do
        'a'
      end
    end
    sequence do
      _print do
        'b'
      end
    end
  end
end
  EOS

  def test_5

    s = OpenWFE::ExpressionTree.to_code_s(TestDefinition5.do_make)

    dotest TestDefinition5, "a\nb"

    assert CODE5, s
  end


  #
  # Test 6
  #

  class TestDefinition6 < OpenWFE::ProcessDefinition

    def initialize (count)
      super()
      @count = count
    end

    def make
      process_definition :name => 'test6', :revision => '0' do
        sequence do
          @count.times do |i|
            _print i
          end
        end
      end
    end
  end

  def test_6

    dotest(
      TestDefinition6.new(3),
      %w{ 0 1 2 }.join("\n"))
  end


  #
  # Test 7
  #

  class TestDefinition7 < OpenWFE::ProcessDefinition
    def make
      _process_definition :name => "test7", :revision => "0" do
        _sequence do
          _print "a"
          _print "b"
        end
      end
    end
  end

  def test_7

    dotest(
      TestDefinition7,
      %w{ a b }.join("\n"))
  end


  #
  # Test 8
  #

  class TestDefinition8 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test8", :revision => "0" do
        toto
        process_definition :name => "toto" do
          _print "toto"
        end
      end
    end
  end

  def test_8

    dotest TestDefinition8, "toto"
  end


  #
  # Test 9
  #

  class TestDefinition9 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test9", :revision => "0" do
        _toto
        process_definition :name => "toto" do
          _print "toto"
        end
      end
    end
  end

  def test_9

    dotest TestDefinition9, "toto"
  end


  #
  # Test 10
  #

  class TestDefinition10 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test10", :revision => "0" do
        sequence do
          participant :ref => "toto_underscore"
          _toto_underscore
          toto_underscore
        end
      end
    end
  end

  def test_10

    @engine.register_participant(:toto_underscore) do |workitem|
      @tracer << "toto\n"
    end

    dotest TestDefinition10, ([ 'toto' ] * 3).join("\n")
  end


  #
  # Test 11
  #

  class TestDefinition11 < OpenWFE::ProcessDefinition
    def make
      sequence do
        [ :b, :b, :b ].each do |p|
          participant p
        end
        participant "b"
      end
    end
  end

  def test_11

    @engine.register_participant(:b) do |workitem|
      @tracer << "b\n"
    end

    dotest TestDefinition11, ([ 'b' ] * 4).join("\n")
  end

  #
  # Test 12
  #

  class TestDefinition12 < OpenWFE::ProcessDefinition
    sequence do
      _print "main"
      sub_x
    end
    process_definition :name => "sub-x" do
      _print "sub"
    end
  end

  def test_12

    dotest TestDefinition12, "main\nsub"
  end


  #
  # Test 13
  #

  class TestDefinition13 < OpenWFE::ProcessDefinition
  end

  def test_13

    dotest TestDefinition13, ''
  end

  #
  # Test 14
  #
  def test_14

    dotest(
      %{<process-definition name="ft_11" revision="t14">
        </process-definition>},
      '')
  end

end

