
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Sep 13 17:46:20 JST 2007
#

require 'fileutils'

require File.dirname(__FILE__) + '/base'


class EftLogTest < Test::Unit::TestCase
  include FunctionalBase

  def test_exp

    File.open('logs/ruote.log', 'w') { |f| f.write('') }

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        log 'log:0'
        log do
          'log:1'
        end
        log :message => 'log:2'
        log :message => 'log:3', :level => 'info'
      end
    end

    log_level_to_debug # required for the sake of the test

    assert_trace(pdef, '')

    #puts IO.read("logs/ruote.log")

    #assert_equal 1, OpenWFE.grep("DEBUG .*log:0", "logs/ruote.log").size
    assert_equal 1, OpenWFE.grep('log:0', 'logs/ruote.log').size

    assert_equal 1, OpenWFE.grep('log:1', 'logs/ruote.log').size
    assert_equal 4, OpenWFE.grep('log:.$', 'logs/ruote.log').size

    #assert_equal 1, OpenWFE.grep("INFO .*log:3", "logs/ruote.log").size
    assert_equal 1, OpenWFE.grep('log:3', 'logs/ruote.log').size
  end
end

