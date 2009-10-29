
#
# Testing Ruote (OpenWFEru)
#
# Sun Jun 14 14:48:03 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class EftUndoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_undo_ref

    pdef = Ruote.process_definition do
      concurrence do
        alpha :tag => 'kilroy'
        undo :ref => 'kilroy'
      end
      echo 'over'
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    assert_trace pdef, %w[ over ]

    assert_equal 0, alpha.size

    assert_equal 1, logger.log.select { |e| e[1] == :entered_tag }.size
    assert_equal 1, logger.log.select { |e| e[1] == :cancel }.size
    assert_equal 1, logger.log.select { |e| e[1] == :left_tag }.size
  end

  def test_undo

    pdef = Ruote.process_definition do
      concurrence do
        alpha :tag => :kilroy
        #undo :kilroy
        cancel :kilroy
      end
      echo 'over'
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    assert_trace pdef, %w[ over ]

    assert_equal 0, alpha.size

    assert_equal 1, logger.log.select { |e| e[1] == :entered_tag }.size
    assert_equal 1, logger.log.select { |e| e[1] == :cancel }.size
    assert_equal 1, logger.log.select { |e| e[1] == :left_tag }.size
  end
end

