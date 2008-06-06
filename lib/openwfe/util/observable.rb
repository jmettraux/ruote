#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

module OpenWFE

  #
  # A classic : this mixin gathers observability methods. It assumes
  # that customer classes will have a @observers instance variable
  # available.
  # This mixin is chiefly used by the ExpressionPool class.
  #
  module OwfeObservable

    #
    # Observers will register themselves to the Observable via
    # this method.
    #
    # An observer is an instance which responds to call(channel, *args)
    #
    # Returns the observer object (or the block's Proc object), could
    # be useful when removing the observer.
    #
    def add_observer (channel, observer=nil, &callback)

      observer = callback unless observer
      (@observers[channel] ||= []) << observer
      observer
    end

    #
    # Removes an observer (this obviously doesn't work well when
    # the actual observer is a block).
    # If a channel is given, the observer will only get removed when
    # registered for that channel.
    #
    def remove_observer (observer, channel=nil)

      channels = if channel
        [ channel ]
      else
        @observers.keys
      end

      channels.each do |c|
        do_remove_observer observer, c
      end
    end

    protected

      #
      # Observable classes do call this method to notify their
      # observers.
      #
      # Returns true if there was an observer registered.
      #
      def onotify (channel, *args)

        do_notify(:all, channel, *args)
        do_notify(channel, channel, *args)
      end

    private

      def do_remove_observer (observer, channel)

        observers = @observers[channel]
        observers.delete(observer) if observers
      end

      def do_notify (target_channel, channel, *args)

        #ldebug { "do_notify() @observers.size is #{@observers.size}" }

        if target_channel.is_a?(String)

          observers = []

          @observers.each do |c, o|

            if c.is_a?(String)
              next unless target_channel.match(c)
            elsif c.is_a?(Regexp)
              next unless c.match(target_channel)
            else
              next
            end

            observers = observers + o
          end
        else

          observers = @observers[target_channel]
        end

        return false unless observers

        observers.each do |obs|
          obs.call channel, *args
        end

        (observers.size > 0)
          #
          # returns true if at least one observer was called
      end
  end
end

