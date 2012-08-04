
#
# testing ruote
#
# Wed Apr  6 08:39:36 JST 2011
#
# Santa Barbara
#

require File.expand_path('../base', __FILE__)

require 'ruote'


class FtWorkitemTest < Test::Unit::TestCase
  include FunctionalBase

  class TraceParticipant
    include Ruote::LocalParticipant

    def consume(wi)
      @context.tracer << "#{wi.wf_name}/#{wi.wf_revision}\n"
      reply_to_engine(wi)
    end
  end

  def test_name_and_revision

    @dashboard.register :alpha, TraceParticipant

    assert_trace(
      'x/y',
      Ruote.process_definition(:name => 'x', :revision => 'y') do
        alpha
      end,
      :clear)

    assert_trace(
      'x/y',
      Ruote.process_definition('x', :revision => 'y') do
        alpha
      end,
      :clear)

    assert_trace(
      'x/y',
      Ruote.process_definition('x', :rev => 'y') do
        alpha
      end,
      :clear)

    assert_trace(
      'x/',
      Ruote.process_definition('x') do
        alpha
      end,
      :clear)

    assert_trace(
      '/',
      Ruote.process_definition do
        alpha
      end,
      :clear)
  end

  def test_wf_launched_at

    pdef = Ruote.define do
      sub0
      define 'sub0' do
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_not_nil r['workitem']['wf_launched_at']
    assert_not_nil r['workitem']['sub_wf_launched_at']
  end

  class SubTraceParticipant
    include Ruote::LocalParticipant

    def consume(wi)
      @context.tracer << "#{wi.sub_wf_name}/#{wi.sub_wf_revision}\n"
      reply_to_engine(wi)
    end
  end

  def test_sub_name_and_sub_revision

    @dashboard.register :bravo, SubTraceParticipant

    assert_trace(
      'x/y',
      Ruote.define('x', :revision => 'y') do
        bravo
      end,
      :clear)

    assert_trace(
      'sub0/',
      Ruote.define('x', :revision => 'y') do
        sub0
        define 'sub0' do
          bravo
        end
      end,
      :clear)

    assert_trace(
      'sub0/2.5',
      Ruote.define('x', :revision => 'y') do
        sub0
        define 'sub0', :revision => '2.5' do
          bravo
        end
      end,
      :clear)

    assert_trace(
      'sub1/',
      Ruote.define('x', :revision => 'y') do
        sub0
        define 'sub0', :revision => '2.5' do
          sub1
        end
        define 'sub1' do
          bravo
        end
      end,
      :clear)

    assert_trace(
      'sub0/2.5',
      Ruote.define('x', :revision => 'y') do
        sub0
        define 'sub0', :revision => '2.5' do
          sub1
          bravo
        end
        define 'sub1' do
          noop
        end
      end,
      :clear)
  end
end

