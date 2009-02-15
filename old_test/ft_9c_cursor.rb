
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Dec 12 23:01:02 JST 2008
#

require 'rubygems'

require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest9c < Test::Unit::TestCase
  include FlowTestBase

  Test0 = OpenWFE.process_definition :name => 'ft_9c', :revision => '0' do
    cursor :rewind_if => '${f:has_error}' do
      alpha
      bravo
    end
  end

  def test_0

    @engine.register_participant :alpha do |workitem|
      @tracer << "a\n"
      workitem.has_error = ( ! workitem.attributes['has_error'])
    end
    @engine.register_participant :bravo do |workitem|
      @tracer << "b\n"
    end

    dotest Test0, %w{ a a b }.join("\n")
  end

end

