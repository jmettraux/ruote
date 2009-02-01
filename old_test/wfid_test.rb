
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require "rubygems"
#require "thread"
#require "fastthread"

require 'test/unit'

require 'openwfe/utils'
require 'openwfe/workitem'
require 'openwfe/engine/engine'
require 'openwfe/expool/wfidgen'
require 'openwfe/def'


#
# testing otime and the scheduler (its cron aspect)
#
class WfidTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

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

    assert true
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

    #puts id

    #assert_equal gen.split_wfid(id).join, id[0, 8]
    assert_equal OpenWFE::split_wfid(id).join, id[0, 8]
  end

  def test_kotoba_wfid

    gen = OpenWFE::KotobaWfidGenerator.new('wfidgen', nil)

    t = Time.now.gmtime
    kid = gen.generate

    #puts "now : #{t}"
    #puts "kid : #{kid}"

    t2 = OpenWFE::KotobaWfidGenerator.to_time(kid)

    #puts "t2  : #{t2}"

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


  #
  # test FieldWfidGenerator

  class MyEngine < OpenWFE::Engine

    def initialize

      super

      self.ac[:definition_in_launchitem_allowed] = true
    end

    def build_wfid_generator

      OpenWFE::FieldWfidGenerator.new(
        :s_wfid_generator, @application_context, 'wfid')
    end
  end

  class MyProcDef < OpenWFE::ProcessDefinition
    sequence do
      # do nothing
    end
  end

  def test_field_wfid

    eng = MyEngine.new

    li = OpenWFE::LaunchItem.new MyProcDef
    li.wfid = 'toto'
    fei = eng.launch(li)

    assert_equal fei.wfid, 'toto'

    li = OpenWFE::LaunchItem.new(MyProcDef)
    fei = eng.launch(li)

    #puts fei.wfid

    assert_not_equal fei.wfid, 'toto'

    t = OpenWFE::KotobaWfidGenerator.to_time(fei.wfid)

    assert t.is_a?(Time)
  end

end
