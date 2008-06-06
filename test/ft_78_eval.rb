
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Tue Nov 20 21:46:30 JST 2007
#

require 'flowtestbase'


class FlowTest78 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # TEST 0
  #

  TEST0 = %{
  <sequence>
    <print>0</print>
    <eval>
      <![CDATA[
      <print>1</print>
      ]]>
    </eval>
    <print>2</print>
  </sequence>
  }.strip

  def test_0

    @engine.ac[:dynamic_eval_allowed] = true

    dotest TEST0, "0\n1\n2"
  end

  #
  # TEST 1
  #

  class Test1 < OpenWFE::ProcessDefinition
    sequence do

      set :var => "v0", :val => "val0"

      set :field => "code", :value => "<print>hello 0</print>"
      _eval :field_def => "code"
      set :field => "code", :value => "_print 'hello 1'"
      _eval :field_def => "code"
      set :variable => "code", :value => "_print 'hello 1'"
      _eval :variable_def => "code"

      set :field => "code", :value => "_print '${v0}'"
      _eval :field_def => "code"

      set :field => "code", :value => "_print '${v0}'", :escape => true
      set :var => "v0", :val => "val0b"
      _eval :field_def => "code"
    end
  end

  def test_1

    @engine.ac[:dynamic_eval_allowed] = true

    dotest Test1, "hello 0\nhello 1\nhello 1\nval0\nval0b"
  end


  #
  # TEST 2
  #

  class Test2 < OpenWFE::ProcessDefinition
    sequence do
      _eval ""
      _print "ok"
    end
  end

  def test_2

    @engine.ac[:dynamic_eval_allowed] = true

    dotest Test2, "ok"
  end


  #
  # TEST 3
  #

  class Test3 < OpenWFE::ProcessDefinition
    sequence do
      _eval "launcher"
      _print "ok"
    end
  end

  def test_3

    @engine.ac[:dynamic_eval_allowed] = true

    @engine.register_participant :launcher do |fexp, wi|
      @tracer << "launcher\n"
      #puts fexp.get_expression_storage.to_s
    end

    dotest Test3, "launcher\nok"
  end


  #
  # TEST 4
  #

  class Test4 < OpenWFE::ProcessDefinition
    _loop do
      _print "before"
      _eval :def => "launcher"
      #launcher
      _print "after"
      _break
    end
  end

  def test_4

    @engine.ac[:dynamic_eval_allowed] = true

    @engine.register_participant :launcher do |fexp, wi|
      @tracer << "launcher\n"
      #@tracer << "#{fexp.get_expression_storage.size}\n"
      #puts fexp.get_expression_storage.to_s
      #puts fexp.to_s
    end

    dotest Test4, "before\nlauncher\nafter"
  end

end

