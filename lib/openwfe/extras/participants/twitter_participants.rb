#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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

#--
# this participant requires the twitter4r gem
#
# http://rubyforge.org/projects/twitter4r/
#
# atom-tools' license is X11/MIT
#++


#require 'rubygems'
#gem 'twitter4r', '0.2.3'
require 'twitter' # gem 'twitter4r'

require 'openwfe/utils'
require 'openwfe/participants/participant'


module OpenWFE
module Extras

  #
  # Sometimes email is a bit too heavy for notification, this participant
  # emit messages via a twitter account.
  #
  # By default, the message emitted is the value of the field
  # "twitter_message", but this behaviour can be changed by overriding
  # the extract_message() method.
  #
  # If the extract_message doesn't find a message, the message will
  # be the result of the default_message method call, of course this
  # method is overridable as well.
  #
  class TwitterParticipant
    include OpenWFE::LocalParticipant

    #
    # The actual twitter4r client instance.
    #
    attr_accessor :client

    #
    # Keeping the initialization params at hand (if any)
    #
    attr_accessor :params

    #
    # This participant expects a login (twitter user name) and a password.
    #
    # The only optional param for now is :no_ssl, which you can set to
    # true if you want the connection to twitter to not use SSL.
    # (seems like the Twitter SSL service is available less often
    # than the plain http one).
    #
    def initialize (login, password, params={})

      super()

      Twitter::Client.configure do |conf|
        conf.protocol = :http
        conf.port = 80
      end if params[:no_ssl] == true

      @client = Twitter::Client.new(
        :login => login,
        :password => password)

      @params = params
    end

    #
    # The method called by the engine when a workitem for this
    # participant is available.
    #
    def consume (workitem)

      user, tmessage = extract_message workitem

      tmessage = default_message(workitem) unless tmessage

      begin

        if user
          #
          # direct message
          #
          tuser = @client.user user.to_s
          @client.message :post, tmessage, tuser
        else
          #
          # just the classical status
          #
          @client.status :post, tmessage
        end

      rescue Exception => e

        linfo do
          "consume() not emitted twitter, because of " +
          OpenWFE::exception_to_s(e)
        end
      end

      reply_to_engine(workitem) if @application_context
    end

    protected

      #
      # Returns a pair : the target user (twitter login name)
      # and the message (or status message if there is no target user) to
      # send to Twitter.
      #
      # This default implementation returns a pair composed with the
      # values of the field 'twitter_target' and of the field
      # 'twitter_message'.
      #
      def extract_message (workitem)

        [ workitem.attributes['twitter_target'],
          workitem.attributes['twitter_message'] ]
      end

      #
      # Returns the default message (called when the extract_message
      # returned nil as the second element of its pair).
      #
      # This default implementation simply returns the workitem
      # FlowExpressionId instance in its to_s() representation.
      #
      def default_message (workitem)

        workitem.fei.to_s
      end
  end

end
end

