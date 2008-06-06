
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest44b < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  class TestCase44b0 < OpenWFE::ProcessDefinition
    sequence do
      set :field => "f", :value => "v"
      save :to_field => "saved"
      #pp_workitem
      _print "${f:saved.f}"
      restore :from_field => "saved"
      _print "${f:saved.f}"
      _print "${f:f}"
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
      set :field => "f", :value => "field_value"
      save :to_variable => "v"
      #pp_workitem
      set :field => "f", :value => "field_value_x"
      _print "${f:f}"
      restore :from_variable => "v"
      _print "${f:f}"
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
      set :field => "f", :value => "field_value"
      save :to_variable => "v"
      restore :from_variable => :v, :to_field => :f1
      #pp_workitem
      _print "${f:f1.f}"
    end
  end

  def test_2

    dotest TestCase44b2, "field_value"
  end


  #
  # Test 3
  #

  class TestCase44b3 < OpenWFE::ProcessDefinition
    sequence do
      set :field => "f0", :value => "value_a"
      save :to_variable => "v"
      set :field => "f0", :value => "value_aa"
      set :field => "f1", :value => "value_b"
      restore :from_variable => :v, :merge_lead => :current
      #pp_workitem
      _print "${f:f0}"
      _print "${f:f1}"
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
      set :field => "f0", :value => "value_a"
      save :to_variable => "v"
      set :field => "f0", :value => "value_aa"
      set :field => "f1", :value => "value_b"
      restore :from_variable => :v, :merge_lead => :restored
      #pp_workitem
      _print "${f:f0}"
      _print "${f:f1}"
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
        "customer" => { "name" => "Zigue", "age" => 34 },
        "approved" => false }
      _print "${f:customer.name} (${f:customer.age}) ${f:approved}"
      #pp_fields
    end
  end

  def test_5

    dotest Test44b5, "Zigue (34) false"
  end

  #
  # Test 6
  #

  class Test44b6 < OpenWFE::ProcessDefinition
    set_fields :value => {
      "customer" => { "name" => "Zigue", "age" => 34 },
      "approved" => false }
    sequence do
      _print "${f:customer.name} (${f:customer.age}) ${f:approved}"
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
        "customer" => { "name" => "Zigue", "age" => 34 },
        "approved" => false
      }
    end
    sequence do
      _print "${f:customer.name} (${f:customer.age}) ${f:approved}"
    end
  end

  def _test_7

    dotest Test44b7, "Zigue (34) false"
  end

  #
  # Test 8
  #

  class Test44b8 < OpenWFE::ProcessDefinition
    set_fields :value => {
      "customer" => { "name" => "Zigue", "age" => 34 },
      "approved" => false }, :merge_lead => :current
    sequence do
      _print "${f:customer.name} (${f:customer.age}) ${f:approved}"
    end
  end

  def test_8

    li = LaunchItem.new Test44b8
    li.approved = true
    dotest li, "Zigue (34) true"
  end

end

