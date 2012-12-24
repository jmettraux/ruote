#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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
  # An abstract class for observing the activity of a ruote engine.
  #
  # Subclass it and add it as a service to observe certain events.
  #
  #   require 'ruote/observer'
  #
  #   class MyLaunchObserver < Ruote::Observer
  #
  #     def on_msg_launch(msg)
  #       puts "just launched process instance #{msg['wfid']}"
  #     end
  #   end
  #
  #   dashboard.add_service('launch_observer', MyLaunchObserver)
  #
  #   # ...
  #
  # Simply add a "on_msg_<msg_name>" method for it to intercept the
  # given messages.
  #
  # See Ruote::ProcessObserver for a base class with precisely defined
  # methods with helpful arguments if you don't want to investigate
  # "msgs" too much.
  #
  class Observer

    def initialize(context)

      @context = context
    end

    def on_pre_msg(msg)

      route('pre', msg)
    end

    def on_msg(msg)

      route(nil, msg)
    end

    protected

    def route(time, msg)

      target = [ 'on', time, 'msg', msg['action'] ].compact.join('_')

      return unless self.respond_to?(target)

      send(target, msg)
    end
  end
end

