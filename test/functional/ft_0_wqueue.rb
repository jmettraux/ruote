
#
# Testing Ruote (OpenWFEru)
#
# Fri May 15 09:51:28 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtWorkqueueTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch_terminate

    #noisy

    pdef = Ruote.process_definition do
    end

    fei = assert_trace pdef, ''

    #p logger.log
    assert_equal 1, logger.log.select { |e| e[1] == :launch }.size
    assert_equal 1, logger.log.select { |e| e[1] == :terminated }.size
  end
end

