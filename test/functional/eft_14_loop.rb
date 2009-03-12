
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Mar 12 12:45:07 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftLoopTest < Test::Unit::TestCase
  include FunctionalBase

  def test_loop

    pdef = OpenWFE.process_definition :name => 'test' do
      repeat do # repeat is an alias to loop
        echo 'a'
        echo 'b'
        final
      end
    end

    counter = 0

    @engine.register_participant 'final' do |workitem|
      counter = counter + 1
      workitem.__cursor_command__ = 'break' if counter > 3
    end

    assert_trace(pdef, (%w{ a b } * 4).join("\n"))
  end
end

