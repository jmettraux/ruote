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

  module ListenerMethods

    #
    # Adds a workitem listener to this engine.
    #
    # The 'freq' parameters if present might indicate how frequently
    # the resource should be polled for incoming workitems.
    #
    #   engine.add_workitem_listener(listener, "3m10s")
    #    # every 3 minutes and 10 seconds
    #
    #   engine.add_workitem_listener(listener, "0 22 * * 1-5")
    #    # every weekday at 10pm
    #
    # TODO : block handling...
    #
    def add_workitem_listener (listener, freq=nil)

      name = if listener.is_a?(Class)

        listener = init_service(nil, listener)

        listener.service_name

      else

        name = listener.name if listener.respond_to?(:name)
        name = "#{listener.class}::#{listener.object_id}" unless name

        @application_context[name] = listener

        listener.application_context = @application_context \
          if listener.respond_to?(:application_context=)

        name
      end

      result = if freq

        freq = freq.to_s.strip

        if Rufus::Scheduler.is_cron_string(freq)

          get_scheduler.schedule(freq, listener)
        else

          get_scheduler.schedule_every(freq, listener)
        end

      else

        nil
      end

      linfo { "add_workitem_listener() added '#{name}'" }

      result
    end

    alias :add_listener :add_workitem_listener
    alias :register_listener :add_workitem_listener

  end
end

