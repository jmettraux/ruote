
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'flowtestbase'
require 'openwfe/expool/history'
require 'openwfe/def'


class FlowTest22 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #

  class TestDefinition0 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test0", :revision => "0" do
        sequence do
          _print "a"
          _print "b"
          _print "c"
        end
      end
    end
  end

  def test_history_0

    @engine.init_service "history", OpenWFE::InMemoryHistory

    history = @engine.application_context["history"]

    dotest TestDefinition0, %w{ a b c }.join("\n")

    puts history.to_s
    #puts history.entries.size()

    #f = File.open("history.log", "w")
    #f.write(history.to_s)
    #f.close()

    assert_equal 22, history.entries.size
  end

  def test_history_1

    @engine.init_service "history", OpenWFE::FileHistory

    dotest TestDefinition0, %w{ a b c }.join("\n")

    @engine.ac["history"].output_file.flush

    linecount = File.open("work/history.log") do |f|
      f.readlines.size
    end

    assert_equal 22, linecount
  end

end

