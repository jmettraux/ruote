
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Jan 25 17:05:36 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftRevalTest < Test::Unit::TestCase
  include FunctionalBase

  def test_no_reval

    @engine.application_context[:ruby_eval_allowed] = false

    pdef = OpenWFE.process_definition :name => 'test' do
      reval '1 + 1'
    end

    fei = @engine.launch(pdef)
    wait(fei)

    ps = @engine.process_status(fei.wfid)

    assert_equal(
      1,
      ps.errors.size)
    assert_equal(
      'evaluation of ruby code is not allowed',
      ps.errors.values.first.stacktrace)

    purge_engine
  end

  def test_reval_text

    @engine.application_context[:ruby_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        reval %{
          workitem.fields['from_ruby'] = 'true'
        }
        _print "${f:from_ruby}"
      end
    end

    assert_trace(pdef, 'true')
  end

  def test_reval_code

    @engine.application_context[:ruby_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        reval :code => "workitem.fields['from_ruby'] = 'true'"
        _print "${f:from_ruby}"
      end
    end

    assert_trace(pdef, 'true')
  end

  def test_reval_return

    @engine.application_context[:ruby_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        set :field => 'f0' do
          reval '1 + 2'
        end
        echo '${f:f0}'
      end
    end

    assert_trace(pdef, '3')
  end

  def test_reval_field

    @engine.application_context[:ruby_eval_allowed] = true

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        set :field => 'f0', :value => '1 + 2'
        echo do
          reval :field_code => 'f0'
        end
      end
    end

    assert_trace(pdef, '3')
  end
end

