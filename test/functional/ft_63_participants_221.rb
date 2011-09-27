
#
# testing ruote
#
# Mon Jun 27 15:18:18 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtParticipantsTwoTwoOne < Test::Unit::TestCase
  include FunctionalBase

  #
  # on_workitem / consume

  class ClassicParticipant
    include Ruote::LocalParticipant
    def consume(workitem)
      (workitem.fields['trace'] ||= []) << workitem.participant_name
      reply_to_engine(workitem)
    end
  end

  class AlphaParticipant
    include Ruote::LocalParticipant
    def on_workitem(workitem)
      (workitem.fields['trace'] ||= []) << workitem.participant_name
      reply_to_engine(workitem)
    end
  end

  class BravoParticipant
    include Ruote::LocalParticipant
    def on_workitem
      (workitem.fields['trace'] ||= []) << workitem.participant_name
      reply_to_engine
    end
  end

  class CharlyParticipant
    include Ruote::LocalParticipant
    def consume
      (workitem.fields['trace'] ||= []) << workitem.participant_name
      reply_to_engine
    end
  end

  class DeltaParticipant
    include Ruote::LocalParticipant
    def on_workitem
      (workitem.fields['trace'] ||= []) << workitem.participant_name
      reply
    end
  end

  def test_on_workitem

    @dashboard.register do
      classic ClassicParticipant
      alpha AlphaParticipant
      bravo BravoParticipant
      charly CharlyParticipant
      delta DeltaParticipant
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      classic; alpha; bravo; charly; delta
    end)

    r = @dashboard.wait_for(wfid)

    assert_equal(
      %w[ classic alpha bravo charly delta ], r['workitem']['fields']['trace'])
  end

  #
  # on_cancel / cancel

  class ZuluParticipant
    include Ruote::LocalParticipant
    def on_workitem
      # do nothing
    end
    def cancel(fei, flavour)
      (workitem.fields['trace'] ||= []) <<
        "#{workitem.participant_name}/#{fei.sid}/#{flavour}"
    end
  end

  class YankeeParticipant
    include Ruote::LocalParticipant
    def on_workitem
      # do nothing
    end
    def on_cancel(fei, flavour)
      (workitem.fields['trace'] ||= []) <<
        "#{workitem.participant_name}/#{fei.sid}/#{flavour}"
    end
  end

  class XrayParticipant
    include Ruote::LocalParticipant
    def on_workitem
      # do nothing
    end
    def on_cancel
      (workitem.fields['trace'] ||= []) <<
        "#{workitem.participant_name}/#{fei.sid}/#{flavour}"
    end
  end

  def test_on_cancel

    @dashboard.register do
      xray XrayParticipant
      yankee YankeeParticipant
      zulu ZuluParticipant
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      xray; yankee; zulu
    end)

    [ :xray, :yankee, :zulu ].each do |participant|
      r = @dashboard.wait_for(participant)
      @dashboard.wait_for(1)
      @dashboard.cancel(r['fei'])
    end

    @dashboard.wait_for(wfid)
  end

  #
  # accept?

  class AcAlphaParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << workitem.participant_name + "\n"
      reply
    end
    def accept?(workitem)
      @context.tracer << "a/#{workitem.participant_name}\n"
      true
    end
  end

  class AcBravoParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << workitem.participant_name + "\n"
      reply
    end
    def accept?
      @context.tracer << "a/#{workitem.participant_name}\n"
      true
    end
  end

  def test_accept

    #@dashboard.noisy = true

    @dashboard.register do
      alpha AcAlphaParticipant
      bravo AcBravoParticipant
    end

    wfid = @dashboard.launch(Ruote.define do
      alpha; bravo
    end)

    @dashboard.wait_for(wfid)

    assert_equal %w[ a/alpha alpha a/bravo bravo ], @tracer.to_a
  end

  #
  # on_reply

  class OrAlphaParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << "ow/#{workitem.participant_name}\n"
      reply
    end
    def on_reply(workitem)
      @context.tracer << "or/#{workitem.participant_name}\n"
    end
  end

  class OrBravoParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << "ow/#{workitem.participant_name}\n"
      reply
    end
    def on_reply
      @context.tracer << "or/#{workitem.participant_name}\n"
    end
  end

  def test_on_reply

    #@dashboard.noisy = true

    @dashboard.register do
      alpha OrAlphaParticipant
      bravo OrBravoParticipant
    end

    wfid = @dashboard.launch(Ruote.define do
      alpha; bravo
    end)

    @dashboard.wait_for(wfid)

    assert_equal %w[ ow/alpha or/alpha ow/bravo or/bravo ], @tracer.to_a
  end

  #
  # do_not_thread? / do_not_thread

  class DntAlphaParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << "ow/#{workitem.participant_name}\n"
      reply
    end
    def do_not_thread(workitem)
      @context.tracer << "dnt/#{workitem.participant_name}\n"
    end
  end

  class DntBravoParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << "ow/#{workitem.participant_name}\n"
      reply
    end
    def do_not_thread?(workitem)
      @context.tracer << "dnt/#{workitem.participant_name}\n"
    end
  end

  class DntCharlyParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << "ow/#{workitem.participant_name}\n"
      reply
    end
    def do_not_thread?
      @context.tracer << "dnt/#{workitem.participant_name}\n"
    end
  end

  class DntDeltaParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << "ow/#{workitem.participant_name}\n"
      reply
    end
    def dont_thread?
      @context.tracer << "dnt/#{workitem.participant_name}\n"
    end
  end

  def test_do_not_thread

    #@dashboard.noisy = true

    @dashboard.register do
      alpha DntAlphaParticipant
      bravo DntBravoParticipant
      charly DntCharlyParticipant
      delta DntDeltaParticipant
    end

    wfid = @dashboard.launch(Ruote.define do
      alpha; bravo; charly; delta
    end)

    @dashboard.wait_for(wfid)

    assert_equal(
      %w[ dnt/alpha ow/alpha
          dnt/bravo ow/bravo
          dnt/charly ow/charly
          dnt/delta ow/delta ],
      @tracer.to_a)
  end

  #
  # on_pause / on_resume

  class OpAlphaParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << "ow/#{workitem.participant_name}\n"
    end
    def on_cancel
      @context.tracer << "oc/#{fei.expid}\n"
    end
    def on_pause(fei)
      @context.tracer << "op/#{fei.expid}\n"
    end
    def on_resume(fei)
      @context.tracer << "or/#{fei.expid}\n"
    end
  end

  class OpBravoParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << "ow/#{workitem.participant_name}\n"
    end
    def on_pause
      @context.tracer << "op/#{fei.expid}\n"
    end
    def on_resume
      @context.tracer << "or/#{fei.expid}\n"
    end
  end

  def test_on_pause_on_resume

    #@dashboard.noisy = true

    @dashboard.register do
      alpha OpAlphaParticipant
      bravo OpBravoParticipant
    end

    wfid = @dashboard.launch(Ruote.define do
      alpha; bravo
    end)

    r = @dashboard.wait_for(:alpha)
    @dashboard.wait_for(1)

    @dashboard.pause(r['fei'])
    @dashboard.wait_for(2)

    @dashboard.resume(r['fei'])
    @dashboard.wait_for(2)

    @dashboard.cancel(r['fei'])

    r = @dashboard.wait_for(:bravo)
    @dashboard.wait_for(1)

    @dashboard.pause(r['fei'])
    @dashboard.wait_for(2)

    @dashboard.resume(r['fei'])
    @dashboard.wait_for(2)

    assert_equal(
      %w[ ow/alpha op/0_0 or/0_0 oc/0_0 ow/bravo op/0_1 or/0_1 ],
      @tracer.to_a)
  end

  #
  # implicit participant name

  class IpnParticipant
    include Ruote::LocalParticipant
    def consume
      @context.tracer << participant_name
      reply
    end
  end

  def test_implicit_participant_name

    @dashboard.register { hypno IpnParticipant }

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      hypno
    end)

    @dashboard.wait_for(wfid)

    assert_equal 'hypno', @tracer.to_s
  end

  #
  # fexp, fexp(fei)
  # workitem, workitem(fei)
  # applied_workitem, applied_workitem(fei)

  class FexpParticipant
    include Ruote::LocalParticipant
    def consume

      @context.tracer << fexp.lookup_variable('nada') + "\n"
      @context.tracer << fexp(fei).lookup_variable('nada') + "\n"

      @context.tracer << workitem.fields.size.to_s + "\n"
      @context.tracer << workitem(fei).fields.size.to_s + "\n"

      @context.tracer << applied_workitem.fields.size.to_s + "\n"
      @context.tracer << applied_workitem(fei).fields.size.to_s + "\n"

      reply
    end
  end

  def test_helper_methods

    @dashboard.register { felix FexpParticipant }

    #@dashboard.noisy = true

    wfid = @dashboard.launch(
      Ruote.define() { felix },
      {},
      { 'nada' => 'surf' })

    @dashboard.wait_for(wfid)

    assert_equal(
      %w[ surf surf 2 1 1 1 ],
      @tracer.to_a)
  end

  #
  # lookup_variable(key)

  class LvParticipant
    include Ruote::LocalParticipant
    def on_workitem
      @context.tracer << lookup_variable('nada') + "\n"
      reply
    end
  end

  def test_lookup_variable

    @dashboard.register { louis LvParticipant }

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define() { louis }, {}, { 'nada' => 'surf' })

    @dashboard.wait_for(wfid)

    assert_equal 'surf', @tracer.to_s
  end
end

