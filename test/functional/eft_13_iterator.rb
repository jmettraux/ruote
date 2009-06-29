
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

  def test_to_f

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'alice, bob, charly', :to_field => 'f' do
        participant '${f:f}'
      end
    end

    @engine.register_participant '.*' do |workitem|
      @tracer << "#{workitem.fields['f']}/#{workitem.fei.expid}\n"
    end

    #noisy

    assert_trace(pdef, %w[ alice/0_0_0 bob/0_0_0 charly/0_0_0 ])
  end

  PDEF0 = Ruote.process_definition :name => 'test' do
    sequence do
      iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        participant '${v:v}'
      end
      echo 'done.'
    end
  end

  def test_break

    @engine.register_participant '.*' do |workitem|

      @tracer << "#{workitem.participant_name}\n"

      workitem.fields['__command__'] = [ 'break', nil ] \
        if workitem.participant_name == 'bob'
    end

    #noisy

    assert_trace(PDEF0, %w[ alice bob done.])
  end

  def test_rewind

    rewound = false

    @engine.register_participant '.*' do |workitem|

      @tracer << "#{workitem.participant_name}\n"

      if (not rewound) and workitem.participant_name == 'bob'
        rewound = true
        workitem.fields['__command__'] = [ 'rewind', nil ]
      end
    end

    #noisy

    assert_trace(PDEF0, %w[ alice bob alice bob charly done.])
  end
end

