
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'rubygems'

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest11b < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #
  # bug #9905 : "NPE" was raised...
  #

  class TestDefinition0 < OpenWFE::ProcessDefinition
    def make
      _print 'ok'
    end
  end

  def test_0
    dotest TestDefinition0.new, 'ok'
  end

  #
  # Test 1
  #

  class TestDefinition1 < OpenWFE::ProcessDefinition
    _print "ok"
  end

  def test_1
    dotest TestDefinition1, 'ok'
  end

  #
  # Test 2
  #

  #Test2 = OpenWFE.process_definition :name => 'ft_11b', :revision => '2' do
  Test2 = OpenWFE.process_definition :name => 'ft_11b' do
    _print '${r:fei.wfname} ${r:fei.wfrevision}'
  end

  def test_2

    dotest Test2, 'ft_11b 0'
  end

  #
  # Test 3
  #

  def test_3

    dotest(
      %{
        OpenWFE::process_definition :name => 'ft_11b', :revision => '3' do
          _print '${r:fei.wfname}'
        end
      },
      'ft_11b')
  end

end

