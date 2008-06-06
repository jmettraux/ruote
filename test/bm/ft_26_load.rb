
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'flowtestbase'
require 'openwfe/def'

include OpenWFE


class FlowTest26c < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #

  class TestDefinition0 < ProcessDefinition
    process_definition :name => "test0", :revision => "0" do
      sequence do
        count
        count
      end
    end
  end
  #class TestDefinition0 < ProcessDefinition
  #  count
  #end

  #def xxxx_load_0
  def test_load_0

    map = {}

    @engine.register_participant("count") do |workitem|
      count = map[workitem.flow_id]
      count = unless count
        1
      else
        count + 1
      end
      map[workitem.flow_id] = count
    end

    n = 1000

    n.times do |i|
      li = LaunchItem.new(TestDefinition0)
      li.flow_id = i
      @engine.launch(li)
    end

    #while @engine.get_expression_storage.size > 1
    #  sleep 0.001
    #end
    @engine.join_until_idle

    good = true

    n.times do |i|
      c = map[i]
      if c == 2
      #if c == 1
        print "."
      else
        print c
        good = false
      end
    end

    #puts "\n__good ? #{good}"
    assert good, "missing count"

    #   100 in  1s (in memory engine)
    #   1'000 in   14s (in memory engine)
    #  10'000 in  143s (in memory engine)
    #   1'000 in   31s (cache engine)
    #  10'000 in  321s (cache engine)
    #   1'000 in  113s (persistence only engine)
    #  10'000 in 1173s (persistence only engine)
    #
    #
    # ruby 1.8.5 (2006-12-25 patchlevel 12) [i686-darwin8.8.3]
    #
    # Machine Name:       Mac
    # Machine Model:      MacBook2,1
    # Processor Name:       Intel Core 2 Duo
    # Processor Speed:      2 GHz
    # Number Of Processors:   1
    # Total Number Of Cores:  2
    # L2 Cache (per processor): 4 MB
    # Memory:           2 GB
    # Bus Speed:        667 MHz

    # Thu Sep 13 15:38:46 JST 2007
    #
    #   100 in  3s (in memory engine)
    #   1'000 in   85s (in memory engine)
    #  10'000 in   s (in memory engine)
  end


  #
  # TEST 1
  #

  def xxxx_load_1
  #def test_load_1

    map = {}

    @engine.register_participant("count") do |workitem|
      count = map[workitem.flow_id]
      count = unless count
        1
      else
        count + 1
      end
      map[workitem.flow_id] = count
      #puts "(#{workitem.flow_id} => #{map[workitem.flow_id]})"
    end

    n = 10000

    n.times do |i|

      #t = Thread.new do
      #  begin
      #    li = LaunchItem.new(TestDefinition0)
      #    li.flow_id = i
      #    @engine.launch(li)
      #    #print "."
      #  rescue Exception => e
      #    print "e"
      #    @engine.lwarn do
      #      "ft_26_test_1 exception...\n" +
      #      OpenWFE::exception_to_s(e)
      #    end
      #  end
      #end

      li = LaunchItem.new(TestDefinition0)
      li.flow_id = i

      fei, t = @engine.launch(li, true)
        #
        # async : true

      t.join if i == n-1
    end

    sleep(1)
    puts

    good = true

    n.times do |i|

      c = map[i]

      if c == 2
        print "."
      elsif c == nil
        print "x"
        good = false
      else
        print c
        good = false
      end
    end

    #puts "\n__good ? #{good}"

    assert good, "missing count"

    #   100 in  3s (in memory engine)
    #   1'000 in   85s (in memory engine)
    #  10'000 in   s (in memory engine)
    #   1'000 in  551s (cache engine)
    #  10'000 in   s (cache engine)
    #   1'000 in   s (persistence only engine)
    #  10'000 in   s (persistence only engine)
    #
    #
    # ruby 1.8.5 (2006-12-25 patchlevel 12) [i686-darwin8.8.3]
    #
    # Machine Name:       Mac
    # Machine Model:      MacBook2,1
    # Processor Name:       Intel Core 2 Duo
    # Processor Speed:      2 GHz
    # Number Of Processors:   1
    # Total Number Of Cores:  2
    # L2 Cache (per processor): 4 MB
    # Memory:           2 GB
    # Bus Speed:        667 MHz
  end

end

