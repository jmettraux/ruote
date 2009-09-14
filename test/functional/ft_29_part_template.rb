
#
# Testing Ruote (OpenWFEru)
#
# Mon Sep 14 19:31:37 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/template'
require 'ruote/part/local_participant'


class FtPartTemplateTest < Test::Unit::TestCase
  include FunctionalBase

  class MyParticipant
    include Ruote::EngineContext
    include Ruote::LocalParticipant
    include Ruote::TemplateMixin

    def initialize (opts={}, &block)

      @block_template = block
      @template = opts[:template]
    end

    def consume (workitem)

      context[:s_tracer] << render_template(expstorage[workitem.fei], workitem)
      context[:s_tracer] << "\n"
      reply_to_engine(workitem)
    end

    def cancel (fei, flavour)
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

    @engine.register_participant(
      :alpha,
      MyParticipant,
      :template => "0:${v:var0}\n1:${f:field0}")

    assert_trace pdef, %w[ 0:v_value 1:f_value done. ]
  end

  def test_block_template

    pdef = Ruote.process_definition :name => 'def0' do
      set 'v:var0' => 'v_value'
      set 'f:field0' => 'f_value'
      alpha
      echo 'done.'
    end

    #noisy

    @engine.register_participant(
      :alpha,
      MyParticipant.new {
        "0:${v:var0}\n1:${f:field0}"
      })

    assert_trace pdef, %w[ 0:v_value 1:f_value done. ]
  end
end

