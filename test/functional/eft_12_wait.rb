
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Feb 24 21:25:58 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftWaitTest < Test::Unit::TestCase
  include FunctionalBase

  def test_wait_until

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence do
          wait :until => '${done} == true', :frequency => '500'
          echo 'a'
        end
        sequence do
          _sleep '350'
          echo 'b'
          set :var => 'done', :val => 'true'
        end
      end
    end

    assert_trace(pdef, "b\na")
  end

  def test_wait_equal

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence do
          wait :frequency => '500' do
            equals :var => 'done', :val => 'true'
          end
          echo 'a'
        end
        sequence do
          _sleep '350'
          echo 'b'
          set :var => 'done', :val => 'true'
        end
      end
    end

    assert_trace(pdef, "b\na")
  end

end

