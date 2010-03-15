
#
# testing ruote
#
# Mon Jun 29 22:29:15 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class EftLoopTest < Test::Unit::TestCase
  include FunctionalBase

  def test_loop

    pdef = Ruote.process_definition :name => 'test' do
      _loop do
        alpha
        bravo
      end
    end

    #noisy

    @engine.register_participant :alpha do |workitem|

      @tracer << "a\n"
      (workitem.fields['count'] ||= 0)
      workitem.fields['count'] += 1
    end

    @engine.register_participant :bravo do |workitem|

      @tracer << "b\n"
      workitem.fields['count'] += 1

      workitem.fields['__command__'] = [ 'break', nil ] \
        if workitem.fields['count'] > 5
    end

    assert_trace(%w[ a b a b a b ], pdef)
  end

  def test_repeat

    pdef = Ruote.process_definition :name => 'test' do
      repeat do
        alpha
      end
    end

    #noisy

    @engine.register_participant :alpha do |workitem|

      @tracer << "a\n"
      (workitem.fields['count'] ||= 0)
      workitem.fields['count'] += 1

      workitem.fields['__command__'] = [ 'break', nil ] \
        if workitem.fields['count'] > 5
    end

    assert_trace(%w[ a a a a a a ], pdef)
  end
end

