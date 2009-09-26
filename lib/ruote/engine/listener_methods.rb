#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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


module Ruote

  #
  # Engine methods for [un]registering participants.
  #
  class Engine

    # Accepts a Listener instance or a Listener class and some options
    #
    # Returns the listener instance.
    #
    def register_listener (listener, opts={}, &block)

      set_listener_name(listener, opts) # as opts[:name]

      raise(ArgumentError.new(
        "There is already a service bound under the name '#{opts[:name]}'"
      )) if @context[opts[:name]]

      l = listener.is_a?(Class) ? listener.new(opts) : listener
      l.context = @context if l.respond_to?(:context)
      class << l
        attr_accessor :scheduler_job_id
        def listener?; true; end
      end
      # TODO : set an @engine instance variable into l ???

      @context[opts[:name]] = l

      if freq = opts[:frequency] || opts[:freq]

        raise(ArgumentError.new(
          "Listener of class #{l.class} can't be called with a frequency " +
          "since it doesn't respond to :call or :trigger"
        )) unless l.respond_to?(:call) || l.respond_to?(:trigger)

        freq = freq.to_s.strip

        job_id = scheduler.every(freq, opts[:name]).job_id

        l.scheduler_job_id = job_id
      end

      wqueue.emit(:listeners, :registered, :name => opts[:name], :listener => l)

      l
    end

    # Removes a listener instance instance from the engine.
    #
    # Makes sure to unschedule it if its a scheduled listener (:frequency).
    #
    def unregister_listener (listener)

      k, v = @context.find { |k, v| v == listener }

      @context.delete(k)

      scheduler.unschedule(v.scheduler_job_id) if v.scheduler_job_id

      wqueue.emit(:listeners, :unregistered, :name => k, :listener => v)
    end

    # Returns a list of registered listeners.
    #
    def listeners

      @context.values.select { |v| v.respond_to?(:listener?) }
    end

    protected

    def set_listener_name (listener, opts)

      opts[:name] ||= "listener_#{opts.object_id}"
    end
  end
end

