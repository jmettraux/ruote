
#
# testing ruote
#
# Mon Sep 14 19:31:37 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'
require 'ruote/part/template'


class FtPartTemplateTest < Test::Unit::TestCase
  include FunctionalBase

  class MyParticipant
    include Ruote::LocalParticipant
    include Ruote::TemplateMixin

    def initialize(opts)

      @template = opts['template']
    end

    def consume(workitem)

      @context['s_tracer'] << render_template(
        @template,
        Ruote::Exp::FlowExpression.fetch(@context, workitem.fei.to_h),
        workitem)
      @context['s_tracer'] << "\n"

      reply_to_engine(workitem)
    end

    def cancel(fei, flavour)
    end
  end

  def test_template

    pdef = Ruote.process_definition :name => 'def0' do
      set 'v:var0' => 'v_value'
      set 'f:field0' => 'f_value'
      alpha
      echo 'done.'
    end

    #noisy

    @dashboard.register_participant(
      :alpha,
      MyParticipant,
      :template => "0:${v:var0}\n1:${f:field0}")

    assert_trace %w[ 0:v_value 1:f_value done. ], pdef
  end
end

