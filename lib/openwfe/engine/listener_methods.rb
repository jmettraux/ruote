#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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
  # Adding the register_listener method to the Engine.
  #
  module ListenerMethods

    #
    # Adds a workitem listener to this engine.
    #
    # This method takes 2 arguments, a listener (or a listener Class) and an
    # optional option list.
    #
    #   engine.register_listener(
    #     OpenWFE::FileListener, :freq => "3m10s")
    #
    # or
    #
    #   engine.register_listener(
    #     OpenWFE::Extras::JabberListener,
    #     :jabber_id => 'jbot', :password => 'wyvern')
    #
    # It's OK to pass an instance of a listener instead of a class.
    #
    #   l = MyCustomListener.new(:a, :b, :c)
    #   engine.register_listener(l)
    #
    # == frequency
    #
    # The :freq or :frequency option if present might indicate how frequently
    # the resource should be polled for incoming workitems.
    #
    #   engine.register_listener(listener, :frequency => "3m10s")
    #    # every 3 minutes and 10 seconds
    #
    #   engine.register_listener(listener, :freq => "0 22 * * 1-5")
    #    # every weekday at 10pm
    #
    # If the frequency is set, this method will return the job_id of the
    # listener in the engine's scheduler. When no frequency is given, nil is
    # returned.
    #
    # TODO : block handling...
    #
    def register_listener (listener, opts={})

      name = get_listener_name(opts)

      l = listener.is_a?(Class) ? listener.new(name, opts) : listener

      l.application_context = @application_context \
        if l.respond_to?(:application_context=) # even if already set

      @application_context[name] = l
        # just to be sure.

      job_id = if freq = opts[:frequency] || opts[:freq]

        freq = freq.to_s.strip

        raise(
          "cannot schedule listener of class '#{l.class}', "+
          "it doesn't have a trigger() method"
        ) unless l.respond_to?(:trigger)

        m = Rufus::Scheduler.is_cron_string(freq) ? :cron : :every
        get_scheduler.send(m, freq, l)

      else

        nil
      end

      linfo { "register_listener() added '#{name}' (#{l.class})" }

      job_id
    end

    alias :add_workitem_listener :register_listener
    alias :add_listener :register_listener

    protected

    def get_listener_name (opts) #:nodoc#

      if name = opts[:name]
        return name
      end

      name = ''
      i = 0

      loop do
        name = "listener_#{i}"
        break unless @application_context[name]
        i += 1
      end
      name
    end

  end
end

