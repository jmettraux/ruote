
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Nov 20 21:46:30 JST 2007
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/util/json'


class EftEvalTest < Test::Unit::TestCase
  include FunctionalBase

  def test_no_eval

    pdef = OpenWFE.process_definition :name => 'test' do
      _eval '_print "1"'
    end

    fei = @engine.launch(pdef)
    wait(fei)

    ps = @engine.process_status(fei.wfid)

    assert_equal(
      1,
      ps.errors.size)
    assert_equal(
      'dynamic evaluation of process definitions is not allowed',
      ps.errors.values.first.stacktrace)

    purge_engine
  end

  def test_eval_text

    @engine.application_context[:dynamic_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        _eval '_print "a"'
        _eval '<print>b</print>'
        _eval '["print",{},["c"]]'

        #_eval ["print",{},["d"]] # NO
      end
    end

    assert_trace(pdef, %w{ a b c }.join("\n"))
  end

  def test_eval_field

    @engine.application_context[:dynamic_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        set :field => 'f', :value => ["print",{},["a"]]
        _eval :field_def => 'f'
      end
    end

    assert_trace(pdef, %w{ a }.join("\n"))
  end

  def test_eval_participant_name

    @engine.application_context[:dynamic_eval_allowed] = true

    @engine.register_participant :fox do |fexp, wi|
      @tracer << "f\n"
    end

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        _eval :def => 'fox'
        _eval 'fox'
      end
    end

    assert_trace(pdef, %w{ f f }.join("\n"))
  end
end

