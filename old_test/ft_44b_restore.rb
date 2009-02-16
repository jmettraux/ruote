
#
# Testing OpenWFEru (Ruote)
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest44b < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #

  class TestCase44b0 < OpenWFE::ProcessDefinition
    sequence do
      set :field => 'f', :value => 'v'
      save :to_field => 'saved'
      #pp_workitem
      _print '${f:saved.f}'
      restore :from_field => 'saved'
      _print '${f:saved.f}'
      _print '${f:f}'
    end
  end

  def test_0

    dotest TestCase44b0, "v\n\nv"
  end


  #
  # Test 1
  #

  class TestCase44b1 < OpenWFE::ProcessDefinition
    sequence do
      set :field => 'f', :value => 'field_value'
      save :to_variable => 'v'
      #pp_workitem
      set :field => 'f', :value => 'field_value_x'
      _print '${f:f}'
      restore :from_variable => 'v'
      _print '${f:f}'
    end
  end

  def test_1

    dotest TestCase44b1, "field_value_x\nfield_value"
  end


  #
  # Test 2
  #

  class TestCase44b2 < OpenWFE::ProcessDefinition
    sequence do
      set :field => 'f', :value => 'field_value'
      save :to_variable => 'v'
      restore :from_variable => :v, :to_field => :f1
      #pp_workitem
      _print '${f:f1.f}'
    end
  end

  def test_2

    dotest TestCase44b2, 'field_value'
  end


  #
  # Test 3
  #

  class TestCase44b3 < OpenWFE::ProcessDefinition
    sequence do
      set :field => 'f0', :value => 'value_a'
      save :to_variable => 'v'
      set :field => 'f0', :value => 'value_aa'
      set :field => 'f1', :value => 'value_b'
      restore :from_variable => :v, :merge_lead => :current
      #pp_workitem
      _print '${f:f0}'
      _print '${f:f1}'
    end
  end

  def test_3

    dotest TestCase44b3, "value_aa\nvalue_b"
  end


  #
  # Test 4
  #

  class TestCase44b4 < OpenWFE::ProcessDefinition
    sequence do
      set :field => 'f0', :value => 'value_a'
      save :to_variable => 'v'
      set :field => 'f0', :value => 'value_aa'
      set :field => 'f1', :value => 'value_b'
      restore :from_variable => :v, :merge_lead => :restored
      #pp_workitem
      _print '${f:f0}'
      _print '${f:f1}'
    end
  end

  def test_4

    dotest TestCase44b4, "value_a\nvalue_b"
  end

  # tests about set_fields...

  #
  # Test 5
  #

  class Test44b5 < OpenWFE::ProcessDefinition
    sequence do
      set_fields :value => {
        'customer' => { 'name' => 'Zigue', 'age' => 34 },
        'approved' => false }
      _print '${f:customer.name} (${f:customer.age}) ${f:approved}'
      #pp_fields
    end
  end

  def test_5

    dotest Test44b5, 'Zigue (34) false'
  end

  #
  # Test 6
  #

  class Test44b6 < OpenWFE::ProcessDefinition
    set_fields :value => {
      'customer' => { 'name' => 'Zigue', 'age' => 34 },
      'approved' => false }
    sequence do
      _print '${f:customer.name} (${f:customer.age}) ${f:approved}'
    end
  end

  def test_6

    dotest Test44b6, "Zigue (34) false"
  end

  #
  # Test 7
  #

  class Test44b7 < OpenWFE::ProcessDefinition
    set_fields do
      {
        'customer' => { 'name' => 'Zigue', 'age' => 34 },
        'approved' => false
      }
    end
    sequence do
      _print '${f:customer.name} (${f:customer.age}) ${f:approved}'
    end
  end

  def _test_7

    dotest Test44b7, 'Zigue (34) false'
  end

  #
  # Test 8
  #

  class Test44b8 < OpenWFE::ProcessDefinition
    set_fields :value => {
      'customer' => { 'name' => 'Zigue', 'age' => 34 },
      'approved' => false }, :merge_lead => :current
    sequence do
      _print "${f:customer.name} (${f:customer.age}) ${f:approved}"
    end
  end

  def test_8

    li = OpenWFE::LaunchItem.new Test44b8
    li.approved = true
    dotest li, 'Zigue (34) true'
  end

  #
  # Test 9
  #

  Test44b9 = %{
<process-definition name="test" revision="44b9">
  <set-fields>
    <a>
      <hash>
        <entry>
          <string>customer_name</string><string>Zigue</string>
        </entry>
        <entry>
          <string>customer_age</string><string>34</string>
        </entry>
        <entry>
          <string>approved</string><false />
        </entry>
      </hash>
    </a>
  </set-fields>
  <sequence>
    <print>${f:customer_name} (${f:customer_age}) ${f:approved}</print>
  </sequence>
</process-definition>
  }

  def test_9

    dotest Test44b9, 'Zigue (34) false'
  end

  #
  # Test 10
  #

  require 'json'

  Test44b10 = %{
<process-definition name="test" revision="44b9">
  <set-fields>
    <a>{"customer":{"name":"Zigue","age":34},"approved":false}</a>
  </set-fields>
  <sequence>
    <print>${f:customer.name} (${f:customer.age}) ${f:approved}</print>
  </sequence>
</process-definition>
  }

  def test_10

    #log_level_to_debug

    dotest Test44b10, 'Zigue (34) false'
  end

  #
  # TEST 11
  #

  class Test44b11 < OpenWFE::ProcessDefinition
    sequence :on_cancel => 'bailout' do
      set :field => 'f0', :value => 'value_a'
      save :to_variable => 'wi'
      set :field => 'f0', :value => 'value_aa'
      _print '${f:f0}'
      cancel_process
    end
    process_definition :name => 'bailout' do
      sequence do
        _print 'bailout'
        #restore :from_variable => 'wi'
        _print "${f:f0}"
      end
    end
  end

  def test_11

    dotest Test44b11, "value_aa\nbailout\nvalue_a"
  end
end

