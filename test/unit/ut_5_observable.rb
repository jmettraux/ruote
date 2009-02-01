
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/util/observable'


class ObservableTest < Test::Unit::TestCase

  class Observed
    include OpenWFE::OwfeObservable

    attr_reader :observers

    def initialize
      super
      @observers = {}
    end

    public :onotify
  end

  def test_0

    $s = nil

    observed = Observed.new

    observed.add_observer :channel0 do
      $s = 0
    end

    observer1 = Object.new
    class << observer1
      def call (channel, *args)
        $s = 1
      end
    end
    observed.add_observer :channel1, observer1

    observer2 = lambda do |channel, args|
      $s = 2
    end
    observed.add_observer :channel2, observer2

    observed.onotify :channel0, :nothing
    assert_equal $s, 0

    observed.onotify :channel1, :nothing
    assert_equal $s, 1

    observed.onotify :channel2, :nothing
    assert_equal $s, 2

    $s = nil

    observed.remove_observer observer2, :channel99

    observed.onotify :channel2, :nothing
    assert_equal $s, 2

    $s = nil

    observed.remove_observer observer2

    observed.onotify :channel2, :nothing
    assert_nil $s

    $s = nil

    observed.remove_observer observer1, :channel1

    observed.onotify :channel1, :nothing
    assert_nil $s
  end


  def test_1

    $s = nil

    observed = Observed.new

    observed.add_observer :channel0 do
      $s = 0
    end
    observed.add_observer 'channel[0-9]+' do
      $s = 9
    end

    $s = nil
    observed.onotify 'channel2', :nothing
    assert_equal $s, 9

    $s = nil
    observed.onotify 'channelZ', :nothing
    assert_nil $s
  end

  def test_2

    observed = Observed.new

    o1 = observed.add_observer :channel0 do
      puts 'whatever'
    end
    o2 = observed.add_observer :channel0 do
      puts 'whatever'
    end

    assert_equal observed.observers.size, 1
    assert_equal observed.observers[:channel0].size, 2

    observed.remove_observer o1

    assert_equal observed.observers.size, 1
    assert_equal observed.observers[:channel0].size, 1

    observed.remove_observer o2

    assert_equal observed.observers.size, 1
    assert_equal observed.observers[:channel0].size, 0
  end

end
