
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

#require 'profile'

require 'flowtestbase'
require 'openwfe/def'


class FlowTest26b < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #

  class TestDefinition0 < ProcessDefinition
    count
  end

  #def xxxx_load_0
  def test_load_0

    #require 'openwfe/expool/journal'
    #@engine.application_context[:keep_journals] = true
    #@engine.init_service("journal", Journal)

    $count = 0

    @engine.register_participant("count") do |workitem|
      $count += 1
      #puts "count is #{$count}"
    end


    n = 1000
    n.times do |i|
      @engine.launch(LaunchItem.new(TestDefinition0))
    end

    puts "launched #{n} items"

    #n.times do |i|
    #  Thread.new do
    #    @engine.launch(LaunchItem.new(TestDefinition0))
    #  end
    #end

    #5.times do
    #  Thread.new do
    #    (n / 5).times do
    #      @engine.launch(LaunchItem.new(TestDefinition0))
    #    end
    #  end
    #end
    #sleep 1

    join_until_idle

    assert_equal $count, n
  end

  def join_until_idle ()
    storage = @engine.get_expression_storage
    while storage.size > 1
      sleep 1
      puts "storage.size:#{storage.size}"
    end
  end

end

