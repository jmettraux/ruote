#
#--
# Copyright (c) 2006-2009, John Mettraux, OpenWFE.org
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
    #   engine.add_workitem_listener(listener, :frequency => "3m10s")
    #    # every 3 minutes and 10 seconds
    #
    #   engine.add_workitem_listener(listener, :freq => "0 22 * * 1-5")
    #    # every weekday at 10pm
    #
    # If the frequency is set, this method will return the job_id of the
    # listener in the engine's scheduler. When no frequency is given, nil is
    # returned.
    #
    # TODO : block handling...
    #
    def register_listener (listener, opts={})

      l = listener.is_a?(Class) ?
        listener.new(@application_context, opts) : listener

      l.application_context = @application_context \
        if l.respond_to?(:application_context=) # even if already set

      name = get_listener_name(l)

      @application_context[name] = l

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

    def get_listener_name (listener) #:nodoc#

      [ :service_name, :name ].each do |m|
        return listener.send(m) if listener.respond_to?(m)
      end

      "#{listener.class}__#{@application_context.size}"
    end

  end
end

