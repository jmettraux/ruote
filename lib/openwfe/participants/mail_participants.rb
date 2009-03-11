#--
# Copyright (c) 2007-2009, Alain Hoang and John Mettraux, OpenWFE.org
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


require 'net/smtp'

require 'openwfe/participants/participant'
require 'openwfe/participants/participants'


module OpenWFE

  #
  # MailParticipant is a simplification of EmailNotificationParticipant.
  #
  # It's initialized in this way :
  #
  #   require 'openwfe/participants/mail_participants'
  #
  #   p = OpenWFE::MailParticipant.new(
  #     :smtp_server => "mailhost.ourcompany.co.jp",
  #     :from_address => "bpms@our.ourcompany.co.jp",
  #     :template => "Dear ${f:name}, you've got mail")
  #
  # or
  #
  #   p = OpenWFE::MailParticipant.new(
  #     :smtp_server => "mailhost.ourcompany.co.jp",
  #     :smtp_port => 25,
  #     :from_address => "bpms@our.ourcompany.co.jp"
  #   ) do |workitem|
  #     s = ""
  #     s << "Dear #{workitem.name},\n"
  #     s << "\n"
  #     s << "it's #{Time.new.to_s} and you've got mail"
  #     s
  #   end
  #
  # As with EmailNotificationParticipant, the "to" address for your email
  # is taken from the workitem's <tt>email_target</tt> field. So, to have
  # the email sent to "foo@nowhere.com", set your workitem's
  # <tt>email_target</tt> field to "foo@nowhere.com" prior to feeding it
  # to the mail participant.
  #
  # Likewise, you can also override the :from_address value by setting the
  # workitems <tt>email_from</tt> field.
  #
  # When passing the mail template as a block, you have
  # four possible arities :
  #   { |workitem| ... }
  #   { |participant_expression, workitem| ... }
  #   { |participant_expression, participant_instance, workitem| ... }
  #   { ... }
  #
  # The smtp server and host default to "127.0.0.1" / 25.
  #
  class MailParticipant

    include LocalParticipant
    include TemplateMixin

    def initialize (params, &block)

      @smtp_server = params[:smtp_server]
      @smtp_port = params[:smtp_port]
      @from_address = params[:from_address]
      @template = params[:template]

      @block_template = block

      # some defaults

      @smtp_server = "127.0.0.1" unless @smtp_server
      @smtp_port = 25 unless @smtp_port
    end

    #
    # The method called each time a workitem reaches this participant
    #
    def consume (workitem)

      fe = get_flow_expression(workitem)
      to_address = workitem.email_target

      #
      # 1. Expand variables

      msg  = eval_template workitem

      from_address = workitem.email_from rescue @from_address

      #puts "msg >>>\n#{msg}<<<"

      #
      # 2. Send message

      Net::SMTP.start(@smtp_server, @smtp_port) do |smtp|
        smtp.send_message(msg, from_address, to_address)
      end

      #
      # 3. Reply to engine

      reply_to_engine(workitem)
    end
  end

  #
  # This participant is used to send an email notification.
  #
  # It's perhaps better to use MailParticipant which is simpler to
  # initialize. This class is anyway an extension of MailParticipant.
  #
  #   require 'openwfe/participants/mail_participants'
  #
  #   @engine.register_participant(
  #     'eno',
  #     OpenWFE::EmailNotificationParticipant.new(
  #       "googlemail.l.google.com",
  #       25,
  #       "eno@outoftheblue.co.jp",
  #       """Subject: test 0
  #
  #   0 : ${r:Time.new}
  #   1 : ${f:customer_name}
  #       """))
  #
  # And then, from the process definition :
  #
  #   class TestDefinition0 < OpenWFE::ProcessDefinition
  #     sequence do
  #       set :field => 'email_target' do
  #         "whatever56x56@gmail.com"
  #       end
  #       set :field => 'customer_name' do
  #         "Monsieur Toto"
  #       end
  #       participant :ref => 'eno'
  #     end
  #   end
  #
  # The 'template' parameter may contain an instance of File instead of
  # an instance of String.
  #
  #   @engine.register_participant(
  #     'eno',
  #     OpenWFE::EmailNotificationParticipant.new(
  #       "googlemail.l.google.com",
  #       25,
  #       "eno@outoftheblue.co.jp",
  #       File.new("path/to/my/mail/template.txt")))
  #
  # You can also define the email template as a Ruby block :
  #
  #   p = EmailNotificationParticipant.new("googlemail.l.google.com", 25, "eno@co.co.jp") do | flowexpression, participant, workitem |
  #
  #     # generally, only the workitem is used within a template
  #
  #     s = ""
  #
  #     # the header of the message
  #
  #     s << "Subject: #{workitem.subject}\n\n"
  #
  #     # then, the body
  #
  #     workitem.attributes.each do |key, value|
  #       s << "- '#{k}' => '#{value}'\n"
  #     end
  #     s << "\ndone.\n"
  #   end
  #
  # Note that the template integrates the subject and requires then a double
  # newline before the message body.
  #
  class EmailNotificationParticipant < MailParticipant

    #
    # Create a new email notification participant.  Requires
    # a mail server, port, a from address, and a mail message template
    #
    def initialize (
      smtp_server, smtp_port, from_address, template=nil, &block)

      params = {}
      params[:smtp_server] = smtp_server
      params[:smtp_port] = smtp_port
      params[:from_address] = from_address

      params[:template] = template if template

      super(params, &block)
    end
  end
end
