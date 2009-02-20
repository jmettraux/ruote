
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Jan  5 22:57:53 JST 2008
#

require File.dirname(__FILE__) + '/base'


class EftExpTest < Test::Unit::TestCase
  include FunctionalBase

  def test_exp

    pdef = OpenWFE.process_definition :name => 'test' do
      exp :name => 'sequence' do
        echo 'a'
        echo 'b'
      end
    end

    assert_trace(pdef, "a\nb")
  end

  def test_exp_1

    @engine.register_participant :alpha do
      @tracer << "alpha\n"
    end

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        exp :name => 'alpha'
        exp :name => 'sub0'
      end
      process_definition :sub0 do
        echo 'sub0'
      end
    end

    assert_trace(pdef, "alpha\nsub0")
  end
end

