
#
# testing ruote
#
# Mon Jun 15 21:18:06 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class EftCancelProcessTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cancel_process

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        cancel_process
        echo 'b'
      end
    end

    #noisy

    assert_trace('a', pdef)

    #assert_equal 3, logger.log.select { |e| e[1] == :entered_tag }.size
  end

  def test_unless

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        cancel_process :unless => 'true == true'
        echo 'b'
      end
    end

    #noisy

    assert_trace("a\nb", pdef)
  end
end

