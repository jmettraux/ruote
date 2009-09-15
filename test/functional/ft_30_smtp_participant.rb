
#
# Testing Ruote (OpenWFEru)
#
# Tue Sep 15 09:04:36 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'mailtrap' # sudo gem install mailtrap
require 'ruote/part/smtp_participant'


class NftSmtpParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  class Trap < Mailtrap
    def puts (s)
      # silent night...
    end
  end

  def test_smtp

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        set 'f:item' => 'cat food'
        alpha
      end
    end

    trapfile = 'work/mailtrap.txt'
    FileUtils.rm(trapfile) rescue nil

    Thread.new do
      Trap.new('127.0.0.1', 2525, true, trapfile)
    end
    sleep 0.050
      # give it some time to start listening

    @engine.register_participant(
      :alpha,
      Ruote::SmtpParticipant,
      :server => '127.0.0.1',
      :port => 2525,
      :to => 'toto@cloudwhatever.ch',
      :from => 'john@outoftheblue.ch',
      :notification => true,
      :template => %{
Hello, do you want ${f:item} ?
      })

    #noisy

    wfid = @engine.launch(pdef)

    sleep 0.350

    assert_match /cat food/, File.read(trapfile)
    assert_nil @engine.process(wfid)
  end
end

