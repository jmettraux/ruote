
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Mar 11 13:44:11 JST 2008
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/workitem'
require 'openwfe/expressions/flowexpression'


class VarFieldLookupTest < Test::Unit::TestCase

  def test_0

    fexp = new_exp({
      'on-value' => 'toto'
    })
    wi = new_wi({
      'toto' => 'whatever'
    })

    assert_equal(
      'toto',
      fexp.lookup_vf_attribute(wi, 'value', :prefix => 'on'))

    fexp = new_exp({ 'on-variable-value' => 'toto' }, { 'toto' => 'surf' })

    assert_equal(
      'surf',
      fexp.lookup_vf_attribute(wi, 'value', :prefix => 'on'))

    fexp = new_exp({ 'on-field-value' => 'toto' })

    assert_equal(
      'whatever',
      fexp.lookup_vf_attribute(wi, 'value', :prefix => 'on'))
  end

  def test_1

    fexp = new_exp({
      'on' => 'surf'
    })
    wi = new_wi

    assert_equal(
      'surf',
      fexp.lookup_vf_attribute(wi, '', :prefix => 'on'))

    assert_equal(
      'surf',
      fexp.lookup_vf_attribute(wi, '', :prefix => :on))
  end

  protected

  def new_exp (atts, vars={})

    fexp = OpenWFE::FlowExpression.new
    fexp.attributes = atts

    fexp.instance_variable_set :@vars, vars

    class << fexp
      def lookup_variable (var_name)
        @vars[var_name]
      end
    end

    fexp
  end

  def new_wi (atts={})

    wi = OpenWFE::InFlowWorkItem.new
    wi.attributes = atts
    wi
  end
end

