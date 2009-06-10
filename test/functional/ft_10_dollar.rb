
#
# Testing Ruote (OpenWFEru)
#
# Wed Jun 10 22:57:18 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtDollarTest < Test::Unit::TestCase
  include FunctionalBase

  def test_dollar

    pdef = Ruote.process_definition do
      sequence do
        echo 'a${v:missing}'
        set :var => 'v0', :val => '0'
        echo 'b${v:v0}'
        echo 'c${var:v0}'
        echo 'd${variable:v0}'
      end
    end

    assert_trace(
      pdef,
      %w[ a b0 c0 d0 ])
  end
end

