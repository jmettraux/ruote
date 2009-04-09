
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Apr 10 08:05:28 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftEvalTest < Test::Unit::TestCase
  include FunctionalBase

  def test_eval_forbidden

    pdef = OpenWFE.process_definition :name => 'test' do
      _eval [ 'echo', {}, [ 'hello.' ] ]
    end

    fei = @engine.launch(pdef)
    wait(fei)
    #sleep 0.350

    assert_equal 1, @engine.process_status(fei).errors.size

    purge_engine
  end

  def test_eval_string_tree

    @engine.application_context[:dynamic_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      _eval "echo 'hello.'"
    end

    assert_trace(pdef, 'hello.')
  end

  def test_eval_tree

    @engine.application_context[:dynamic_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      _eval :def => [ 'echo', {}, [ 'hello.' ] ]
    end

    assert_trace(pdef, 'hello.')
  end

  def test_makarand_insert

    @engine.application_context[:dynamic_eval_allowed] = true

    pdef0 = [ 'echo', {}, [ 'hello.' ] ]

    pdef = OpenWFE.process_definition :name => 'test' do
      _eval :def => pdef0
    end

    assert_trace(pdef, 'hello.')
  end

  def test_xml_cdata_eval

    @engine.ac[:dynamic_eval_allowed] = true

    pdef = %{
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

    assert_trace pdef, "0\n1\n2"
  end

  def test_field_var_escape_eval

    @engine.ac[:dynamic_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        set :var => "v0", :val => "val0"

        set :field => "code", :value => "<print>hello 0</print>"
        _eval :field_def => "code"
        set :field => "code", :value => "echo 'hello 1'"
        _eval :field_def => "code"
        set :variable => "code", :value => "echo 'hello 1'"
        _eval :variable_def => "code"

        set :field => "code", :value => "echo '${v0}'"
        _eval :field_def => "code"

        set :field => "code", :value => "echo '${v0}'", :escape => true
        set :var => "v0", :val => "val0b"
        _eval :field_def => "code"
      end
    end

    assert_trace pdef, "hello 0\nhello 1\nhello 1\nval0\nval0b"
  end


  def test_3

    @engine.ac[:dynamic_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        _eval 'launcher'
        echo 'ok'
      end
    end

    @engine.register_participant :launcher do |fexp, wi|
      @tracer << "launcher\n"
      #puts fexp.get_expression_storage.to_s
    end

    assert_trace pdef, "launcher\nok"
  end

end

