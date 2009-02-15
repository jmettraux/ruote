
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/expool/wfidgen'


#
# testing otime and the scheduler (its cron aspect)
#
class WfidTest < Test::Unit::TestCase

  def test_wfid_0

    gen = OpenWFE::DefaultWfidGenerator.new('wfidgen', nil)

    thread = nil

    n = 777
    #n = 1000000

    map = {}

    n.times do |i|

      thread = Thread.new do

        wfid = gen.generate

        #puts wfid

        abort "\nduplicate workflow_instance_id found !!!" \
          if map[wfid]

        map[wfid] = true

        #puts wfid if i == n-1
      end
    end

    thread.join

    sleep(0.1)
    #puts

    assert_equal map.size, n
  end

  def test_wfid_1

    gen = OpenWFE::DefaultWfidGenerator.new('wfidgen', nil)

    a = %w{ 1 2 3 4 5 }
    s = a.join

    #a2 = gen.split_wfid(s)
    a2 = OpenWFE::split_wfid(s)

    assert_equal a, a2
  end

  def test_wfid_2

    gen = OpenWFE::UuidWfidGenerator.new('wfidgen', nil)

    id = gen.generate

    #assert_equal gen.split_wfid(id).join, id[0, 8]
    assert_equal OpenWFE::split_wfid(id).join, id[0, 8]
  end

  def test_kotoba_wfid

    gen = OpenWFE::KotobaWfidGenerator.new('wfidgen', nil)

    t = Time.now.gmtime
    kid = gen.generate

    t2 = OpenWFE::KotobaWfidGenerator.to_time(kid)

    assert_equal t.to_s, t2.to_s

    #t = Time.utc(2007, 03, 20, 23, 59, 59)
    #kid = OpenWFE::KotobaWfidGenerator.from_time(t)
    #puts t
    #puts kid
    #kid = "20070320-nayozumuja"
    #puts OpenWFE::KotobaWfidGenerator.to_time(kid)
    #kid = "20070320-nayozumuje"
    #puts OpenWFE::KotobaWfidGenerator.to_time(kid)
    #kid = "20070320-nayozunuje"
    #puts OpenWFE::KotobaWfidGenerator.to_time(kid)
    #kid = "20070320-nazazunuje"
    #puts OpenWFE::KotobaWfidGenerator.to_time(kid)
  end

end
