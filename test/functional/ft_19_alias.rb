
#
# Testing Ruote (OpenWFEru)
#
# Thu Jul 16 16:11:57 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtAliasTest < Test::Unit::TestCase
  include FunctionalBase

  def test_var_alias

    pdef = Ruote.process_definition :name => 'def0' do
      set :v => 'alpha', :val => 'bravo'
      sequence do
        alpha
        bravo
      end
    end

    alpha = @engine.register_participant :bravo do |workitem|
      @tracer << "b:#{workitem.fields['params']['original_ref']}\n"
    end

    #noisy

    assert_trace(pdef, %w[ b:alpha b: ])
  end
end

