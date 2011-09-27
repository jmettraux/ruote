
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

  def test_wf_info

    @dashboard.register :alpha, TraceParticipant

    #@dashboard.noisy = true

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
end

