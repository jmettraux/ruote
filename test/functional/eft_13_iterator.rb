
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Jun 29 09:35:48 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftIteratorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_iterator

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace(pdef, 'done.')
  end

  def test_iterator

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        participant '${v:v}'
      end
    end

    @engine.register_participant '.*' do |workitem|
      @tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
    end

    #noisy

    assert_trace(pdef, %w[ alice/0_0_0 bob/0_0_0 charly/0_0_0 ])
  end
end

