
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Jan 24 22:40:35 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftSequenceTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_sequence

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
      end
    end

    assert_trace(pdef, '')
  end

  def test_a_b_sequence

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        echo 'a'
        echo 'b'
      end
    end

    assert_trace(pdef, "a\nb")
  end
end

