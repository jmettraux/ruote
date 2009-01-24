
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest47 < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #

  class TestFilter47a0 < OpenWFE::ProcessDefinition
    sequence do
      _print "${v0}"
      _print "${v1}"
      filter_definition :name => "filter1" do
      end
      _defined :variable => :filter0
      _print "${f:__result__}"
      _defined :variable => :filter1
      _print "${f:__result__}"
    end
    filter_definition :name => "filter0" do
    end
    set :variable => "v0", :value => "toto"
    set :variable => "v1", :value => "hector"
  end

  def test_0
    #log_level_to_debug
    dotest(TestFilter47a0, "toto\nhector\ntrue\ntrue")
  end


  #
  # Test 1
  #

  class TestFilter47a1 < OpenWFE::ProcessDefinition
    sequence do

      set :field => "readable", :value => "bible"
      set :field => "writable", :value => "sand"
      set :field => "randw", :value => "notebook"
      set :field => "hidden", :value => "playboy"

      toto
      toto :filter => "filter0"

      _print "${f:readable}"
      _print "${f:writable}"
      _print "${f:randw}"
      _print "${f:hidden}"
    end

    filter_definition :name => "filter0" do
      field :regex => "readable", :permissions => "r"
      field :regex => "writable", :permissions => "w"
      field :regex => "randw", :permissions => "rw"
      field :regex => "hidden", :permissions => ""
    end
  end

  def test_1

    @engine.register_participant :toto do |workitem|

      @tracer << "filter.size is #{workitem.filter.fields.size}\n" \
        if workitem.filter

      @tracer << "r  : #{workitem.attributes['readable']}\n"
      @tracer << "w  : #{workitem.attributes['writable']}\n"
      @tracer << "rw : #{workitem.attributes['randw']}\n"
      @tracer << "h  : #{workitem.attributes['hidden']}\n"
      @tracer << "--\n"
    end

    dotest(
      TestFilter47a1,
      """
r  : bible
w  : sand
rw : notebook
h  : playboy
--
filter.size is 4
r  : bible
w  : 
rw : notebook
h  : 
--
bible
sand
notebook
playboy
      """.strip)
  end


  #
  # Test 2
  #

  class TestFilter47a2 < OpenWFE::ProcessDefinition
    sequence do

      set :field => "readable", :value => "bible"
      set :field => "writable", :value => "sand"
      set :field => "randw", :value => "notebook"
      set :field => "hidden", :value => "playboy"

      alice :filter => "filter0"
      pp_fields
    end

    filter_definition :name => "filter0" do
      field :regex => "readable", :permissions => "r"
      field :regex => "writable", :permissions => "w"
      field :regex => "randw", :permissions => "rw"
      field :regex => "hidden", :permissions => ""
    end
  end

  def test_2

    @engine.register_participant :alice do |workitem|
      workitem.readable = "nada"
      workitem.writable = "nada"
      workitem.randw = "nada"
      workitem.hidden = "nada"
    end

    dotest(
      TestFilter47a2,
      %{
hidden: playboy
randw: nada
readable: bible
writable: nada
--
      }.strip)
  end

  #
  # Test 3
  #

  Test3 = OpenWFE.process_definition :name => 'ft47t3' do

    alice :filter => 'filter0'

    filter_definition :name => 'filter0' do
      field :regex => 'readable', :permissions => 'r'
      field :regex => 'writable', :permissions => 'w'
      field :regex => 'randw', :permissions => 'rw'
      field :regex => 'hidden', :permissions => ''
    end
  end

  FILTER_3 = {"class"=>"OpenWFE::FilterDefinition", "fields"=>[{"regex"=>"--- readable\n", "class"=>"OpenWFE::FilterDefinition::Field", "permissions"=>"r"}, {"regex"=>"--- writable\n", "class"=>"OpenWFE::FilterDefinition::Field", "permissions"=>"w"}, {"regex"=>"--- randw\n", "class"=>"OpenWFE::FilterDefinition::Field", "permissions"=>"rw"}, {"regex"=>"--- hidden\n", "class"=>"OpenWFE::FilterDefinition::Field", "permissions"=>""}], "add_ok"=>false, "remove_ok"=>false, "closed"=>false}

  def test_3

    $filter = nil
    $workitem = nil

    @engine.register_participant :alice do |workitem|
      #p workitem.filter.to_h
      @tracer << 'ok'
      $workitem = workitem.dup
      $filter = workitem.to_h['attributes']['__filter__']
    end

    dotest(Test3, 'ok')

    assert_equal(FILTER_3, $filter)

    wi = OpenWFE.workitem_from_h($workitem.to_h)

    assert_equal(FILTER_3, wi.filter.to_h)
  end

end

