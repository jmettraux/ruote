
#
# testing ruote
#
# Sat Jun 13 22:43:16 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/part/local_participant'


class FtRecursionTest < Test::Unit::TestCase
  include FunctionalBase

  class CountingParticipant
    include Ruote::LocalParticipant

    def consume(workitem)

      @context.stash[:wfids] ||= []
      @context.stash[:wfids] << "#{workitem.fei.wfid}|#{workitem.fei.subid}"

      workitem.fields['count'] ||= 0
      workitem.fields['count'] = workitem.fields['count'] + 1

      @context.tracer << workitem.fields['count'].to_s + "\n"

      if workitem.fields['count'] > 5
        @context.engine.cancel_process(workitem.fei.wfid)
      else
        reply_to_engine(workitem)
      end
    end

    def cancel(fei, flavour)
    end
  end

  def test_main_recursion

    @dashboard.context.stash[:wfids] = []

    pdef = Ruote.process_definition :name => 'def0' do
      sequence do
        alpha
        def0
      end
    end

    alpha = @dashboard.register_participant :alpha, CountingParticipant

    #noisy

    assert_trace(%w[ 1 2 3 4 5 6 ], pdef)

    assert_equal 6, @dashboard.context.stash[:wfids].uniq.size
  end

  def test_sub_recursion

    @dashboard.context.stash[:wfids] = []

    pdef = Ruote.process_definition do
      define 'sub0' do
        sequence do
          alpha
          sub0
        end
      end
      sub0
    end

    alpha = @dashboard.register_participant :alpha, CountingParticipant

    #noisy

    assert_trace %w[ 1 2 3 4 5 6 ], pdef

    #p alpha.wfids.uniq

    assert_equal 6, @dashboard.context.stash[:wfids].uniq.size
  end

  def test_forgotten_main_recursion

    pdef = Ruote.process_definition :name => 'def0' do
      sequence do
        alpha
        forget do
          def0
        end
      end
    end

    alpha = @dashboard.register_participant :alpha, CountingParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    6.times { wait_for(:alpha) }

    wait_for(1)

    assert_equal((1..6).to_a.join("\n"), @tracer.to_s)
  end
end

