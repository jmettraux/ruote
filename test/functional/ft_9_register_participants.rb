
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Wed Mar 11 13:02:17 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtRegisterParticipantsTest < Test::Unit::TestCase
  include FunctionalBase

  #
  # some preparation...

  PDEF = OpenWFE.process_definition 'test' do
    sequence do
      alpha
      echo '${f:reply}'
    end
  end

  class AaParticipant
    include OpenWFE::LocalParticipant

    def consume (workitem)
      workitem.reply = 'alright'
      reply_to_engine(workitem)
    end
  end

  class BbParticipant
    include OpenWFE::LocalParticipant

    def initialize (opts)
      @message = opts[:message]
    end
    def consume (workitem)
      workitem.reply = @message
      reply_to_engine(workitem)
    end
  end

  class CcParticipant
    include OpenWFE::LocalParticipant

    def consume (workitem)
      workitem.reply = 'clright'
      reply_to_engine(workitem)
    end
  end

  #
  # the tests...

  def test_register_block

    @engine.register_participant 'alpha' do |workitem|
      @tracer << "ok\n"
    end

    assert_trace(PDEF, 'ok')
  end

  def test_register_class

    @engine.register_participant 'alpha', AaParticipant

    assert_trace(PDEF, 'alright')
  end

  def test_register_class_with_options

    @engine.register_participant(
      'alpha', BbParticipant, { :message => 'blright' })

    assert_trace(PDEF, 'blright')
  end

  def test_register_instance

    @engine.register_participant 'alpha', CcParticipant.new

    assert_trace(PDEF, 'clright')
  end
end

