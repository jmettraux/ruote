
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'test/unit'

require 'openwfe/workitem'
require 'openwfe/engine/engine'
require 'openwfe/def'
require 'openwfe/participants/participants'
require 'openwfe/participants/enoparticipants'

require 'rubygems'
require 'mailtrap'


class EnoTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class TestDefinition0 < OpenWFE::ProcessDefinition
        email_notification_participant
    end

    def test_eno

        mailfile = "work/mailtrap.txt"

        FileUtils.mkdir "work" unless File.exist?("work")
        FileUtils.rm mailfile if File.exist?(mailfile)
        Thread.new do
            Mailtrap.new 'localhost', 2525, true, "work/mailtrap.txt"
        end

        engine = Engine.new

        eno = OpenWFE::MailParticipant.new(
            :smtp_server => "localhost",
            :smtp_port => 2525,
            :from_address => "eno@outoftheblue.co.jp"
        ) do

            s = ""
            s << "Subject: test 0\n"
            s << "\n"
            s << "konnichiwa. #{Time.now.to_s}\n\n"

            s
        end

        engine.register_participant("email_notification_participant", eno)

        li = OpenWFE::LaunchItem.new TestDefinition0

        li.email_target = 'john@localhost'

        fei = engine.launch li
        engine.wait_for fei

        assert_equal 1, OpenWFE.grep("konnichiwa", mailfile).size
    end
end

