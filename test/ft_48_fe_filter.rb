
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest48 < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #

  class TestFilter48a0 < OpenWFE::ProcessDefinition
    sequence do

      set :field => "readable", :value => "bible"
      set :field => "writable", :value => "sand"
      set :field => "randw", :value => "notebook"
      set :field => "hidden", :value => "playboy"

      alice

      filter :name => "filter0" do
        alice
      end

      alice
    end

    filter_definition :name => "filter0" do
      field :regex => "readable", :permissions => "r"
      field :regex => "writable", :permissions => "w"
      field :regex => "randw", :permissions => "rw"
      field :regex => "hidden", :permissions => ""
    end
  end

  def test_0

    @engine.register_participant :alice do |workitem|

      @tracer << "filter.size is #{workitem.filter.fields.size}\n" \
        if workitem.filter

      @tracer << "r  : #{workitem.attributes['readable']}\n"
      @tracer << "w  : #{workitem.attributes['writable']}\n"
      @tracer << "rw : #{workitem.attributes['randw']}\n"
      @tracer << "h  : #{workitem.attributes['hidden']}\n"
      @tracer << "--\n"
    end

    dotest(
      TestFilter48a0,
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
r  : bible
w  : sand
rw : notebook
h  : playboy
--
      """.strip)
  end

end

