
#
# Testing Ruote (OpenWFEru)
#
# Wed May 20 09:23:01 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftSetTest < Test::Unit::TestCase
  include FunctionalBase

  def test_set_var

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'x', :value => '0'
        echo '-${v:x}-'
      end
    end

    #noisy

    assert_trace pdef, '-0-'
  end
end

