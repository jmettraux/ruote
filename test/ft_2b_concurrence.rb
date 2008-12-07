
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest2b < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  def prepare
    [ "alpha", "bravo", "charly" ].each do |name|

      @engine.register_participant(name) do |workitem|

        workitem.attributes[name] = true
        workitem.attributes["key"] = name
      end
    end

    #@engine.register_participant("display_workitem") do |workitem|
    #  puts
    #  puts
    #end
  end

  #
  # TEST 0

  def test_con_0

    prepare()

    dotest(
      '''
<process-definition name="2b_con" revision="0">
  <sequence>
    <concurrence
      merge="lowest"
      merge-type="mix"
    >
      <participant ref="alpha" />
      <participant ref="bravo" />
      <participant ref="charly" />
    </concurrence>
    <!--
    <print>${r:workitem.to_s}</print>
    <reval>puts "---r:" + workitem.key.to_s</reval>
    -->
    <print>${f:key}</print>
  </sequence>
</process-definition>''',
      "charly")
  end

  #
  # TEST 1

  class TestDefinition1 < OpenWFE::ProcessDefinition

    def initialize (merge, merge_type)
      super()
      @merge = merge
      @merge_type = merge_type
    end

    def make
      _process_definition :name => "2b_con", :revision => "1" do
        _sequence do
          _concurrence :merge => @merge, :merge_type => @merge_type do
            [ "alpha", "bravo", "charly" ].each do |pname|
              _participant pname
            end
          end
          #_reval "puts workitem.to_s"
          #_reval "puts '${f:key}|${f:alpha}|${f:bravo}|${f:charly}'"
          _print "${f:key}\n${f:alpha}\n${f:bravo}\n${f:charly}"
        end
      end
    end
  end

  def test_con_1

    #log_level_to_debug

    prepare

    dotest(
      TestDefinition1.new("lowest", "mix"),
      %w{ charly true true true }.join("\n"))
  end

  def test_con_1b

    prepare

    dotest(
      TestDefinition1.new("highest", "mix"),
      %w{ alpha true true true }.join("\n"))
  end

  def test_con_1c

    prepare

    dotest(
      TestDefinition1.new("lowest", "override"),
      [ 'charly', '', '', 'true' ].join("\n"))
  end

  def test_con_1d

    prepare

    dotest(
      TestDefinition1.new("highest", "override"),
      %w{ alpha true }.join("\n"))
  end

  def test_rawprog

    #puts TestDefinition1.new("lowest", "mix").make.to_s

    assert_equal(
      "<process-definition name='2b_con' revision='1'>"+
      "<sequence>"+
      "<concurrence merge='lowest' merge-type='mix'>"+
      "<participant>"+
      "alpha"+
      "</participant>"+
      "<participant>"+
      "bravo"+
      "</participant>"+
      "<participant>"+
      "charly"+
      "</participant>"+
      "</concurrence>"+
      "<print>"+
      "${f:key}\n${f:alpha}\n${f:bravo}\n${f:charly}"+
      "</print>"+
      "</sequence>"+
      "</process-definition>",
      OpenWFE::ExpressionTree.to_s(
        TestDefinition1.new("lowest", "mix").make))
  end


  #
  # TEST 2

  class Isolate01 < OpenWFE::ProcessDefinition
    N = 3
    sequence do
      #concurrence :merge_type => :isolate do
      concurrence :merge_type => "isolate" do
        N.times do |x|
          set :field => "f", :value => "#{x}"
        end
      end
      #pp_workitem
      N.times do |x|
        _print "${r:wi.attributes['#{x}']['f']}"
      end
    end
  end

  def test_2

    dotest Isolate01, "0\n1\n2"
  end

end

