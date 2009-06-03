
#
# Testing Ruote (OpenWFEru)
#
# Tue Jun  2 18:48:02 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtOnErrorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_error

    pdef = Ruote.process_definition do
      sequence :on_error => 'catcher' do
        nada
      end
    end

    @engine.register_participant :catcher do
      @tracer << "caught\n"
    end

    noisy

    assert_trace(pdef, 'caught')
  end
end

