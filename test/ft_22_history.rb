
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/expool/history'
require 'openwfe/def'


class FlowTest22 < Test::Unit::TestCase
  include FlowTestBase

  class TestDefinition0 < OpenWFE::ProcessDefinition
    sequence do
      _print 'a'
      _print 'b'
      participant 'c'
    end
  end

  def test_0

    @engine.register_participant 'c' do
      @tracer << "c\n"
    end

    @engine.init_service 'history', OpenWFE::InMemoryHistory

    history = @engine.application_context['history']

    dotest TestDefinition0, %w{ a b c }.join("\n")

    #puts history.to_s
    #puts history.entries.size()

    #f = File.open("history.log", "w")
    #f.write(history.to_s)
    #f.close()

    assert_equal 4, history.entries.size
  end

  def test_1

    @engine.register_participant 'c' do
      @tracer << "c\n"
    end

    @engine.init_service "history", OpenWFE::FileHistory

    dotest TestDefinition0, %w{ a b c }.join("\n")

    @engine.ac["history"].output_file.flush

    linecount = File.open("work/history.log") do |f|
      f.readlines.size
    end

    assert_equal 4, linecount
  end

end

