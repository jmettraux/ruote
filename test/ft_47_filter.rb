
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
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

end

