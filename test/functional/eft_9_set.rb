
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Feb  3 16:40:16 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftSetTest < Test::Unit::TestCase
  include FunctionalBase

  def test_set_variables

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        set :v => 'v0', :value => 'a'
        set :var => 'v1', :value => 'b'
        set :variable => 'v2', :value => 'c'

        set :v => 'v3', :val => 'd'
        set :var => 'v4', :v => 'e' # doesn't work, hence no 'e'

        echo '${v0} ${v1} ${v2} ${v3} ${v4}'
      end
    end

    assert_trace(pdef, 'a b c d')
  end

  def test_set_var_not_string

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        set :v => 'v0', :value => [ 1, 2 ]

        echo '${v0}'
      end
    end

    assert_trace(pdef, ruby18 ? '12' : '[1, 2]')
  end

  def test_set_fields

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        set :f => 'f0', :val => 'a'
        set :fld => 'f1', :val => 'b'
        set :field => 'f2', :val => 'c'

        echo '${f:f0} ${f:f1} ${f:f2}'
      end
    end

    assert_trace(pdef, 'a b c')
  end

  def test_set_field_not_string

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        set :f => 'f0', :value => [ 1, 2 ]

        echo '${f:f0}'
      end
    end

    assert_trace(pdef, ruby18 ? '12' : '[1, 2]')
  end

  def test_set_escaped

    @engine.register_participant :peek do |workitem|
      @tracer << workitem.fields['f0']
      @tracer << workitem.fields['f1']
    end

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        set :f => 'f0', :value => '.${v0}', :escape => 'true'
        set :f => 'f1', :value => '.${v1}', :escape => true
        peek
      end
    end

    assert_trace(pdef, '.${v0}.${v1}')
  end

  def test_set_nested

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        set :f => 'f0' do
          'a'
        end

        echo '${f:f0}'
      end
    end

    assert_trace(pdef, 'a')
  end

  def test_set_fval_varval

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        set :f => 'f0', :value => 'a'
        set :v => 'v0', :value => '0'
        set :f => 'f1', :variable_value => 'v0'
        set :v => 'v1', :field_value => 'f0'
        set :f => 'f2', :var_value => 'v0'
        set :v => 'v2', :f_value => 'f0'

        echo '${f:f0} ${v0} ${f:f1} ${v1} ${f:f2} ${v2}'
      end
    end

    assert_trace(pdef, 'a 0 0 a 0 a')
  end
end

