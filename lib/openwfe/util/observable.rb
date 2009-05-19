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

      #observer = callback unless observer
      observer ||= callback
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

      channels = channel ? [ channel ] : @observers.keys

      channels.each { |c| do_remove_observer(observer, c) }
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

      observers = if target_channel.is_a?(String)

        @observers.inject([]) do |r, (c, o)|

          if c.is_a?(String)
            r += o if target_channel.match(c)
          elsif c.is_a?(Regexp)
            r += o if c.match(target_channel)
          end

          r
        end
      else

        @observers[target_channel]
      end

      return false unless observers

      observers.each { |obs| obs.call(channel, *args) }

      (observers.size > 0)
        #
        # returns true if at least one observer was called
    end
  end
end

