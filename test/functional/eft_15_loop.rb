
#
# testing ruote
#
# Mon Jun 29 22:29:15 JST 2009
#

require File.expand_path('../base', __FILE__)


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

    @dashboard.register_participant :alpha do |workitem|

      tracer << "a\n"
      (workitem.fields['count'] ||= 0)
      workitem.fields['count'] += 1
    end

    @dashboard.register_participant :bravo do |workitem|

      tracer << "b\n"
      workitem.fields['count'] += 1

      if workitem.fields['count'] > 5
        workitem.fields['__command__'] = [ 'break', nil ]
      end
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

    @dashboard.register_participant :alpha do |workitem|

      tracer << "a\n"
      (workitem.fields['count'] ||= 0)
      workitem.fields['count'] += 1

      if workitem.fields['count'] > 5
        workitem.fields['__command__'] = [ 'break', nil ]
      end
    end

    assert_trace(%w[ a a a a a a ], pdef)
  end
end

