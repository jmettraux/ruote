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


require 'logger'
require 'openwfe/utils'


module OpenWFE

  #
  # A Mixin for adding logging method to any class
  #
  module Logging

    def ldebug (message=nil, &block)
      do_log(:debug, message, &block)
    end

    def linfo (message=nil, &block)
      do_log(:info, message, &block)
    end

    def lwarn (message=nil, &block)
      do_log(:warn, message, &block)
    end

    def lerror (message=nil, &block)
      do_log(:error, message, &block)
    end

    def lfatal (message=nil, &block)
      do_log(:fatal, message, &block)
    end

    def lunknown (message=nil, &block)
      do_log(:unknown, message, &block)
    end

    def llog (level, message=nil, &block)
      do_log(level, message, &block)
    end

    #
    # A simplification of caller_to_s for direct usage when debugging
    #
    def ldebug_callstack (msg, max_lines=nil)

      ldebug { "#{msg}\n" + OpenWFE::caller_to_s(9, max_lines) }
    end

    private

    def do_log (level, message, &block)

      return unless $OWFE_LOG

      logblock = lambda do
        if block
          "#{log_prepare(message)} - #{block.call}"
        else
          "#{log_prepare(message)}"
        end
      end

      # If somebody (ActiveSupport) changed the formatter, let's
      # undo it.

      if $OWFE_LOG.respond_to?(:formatter) && $OWFE_LOG.formatter.class == Logger::Formatter
        $OWFE_LOG.formatter = Logger::Formatter.new
      end

      $OWFE_LOG.send(level, &logblock)
    end

    def log_prepare (message)

      return log_author() unless message
      "#{log_author} - #{message}"
    end

    def log_author

      if respond_to?(:service_name)
        "#{self.class} '#{self.service_name}'"
      else
        "#{self.class}"
      end
    end

  end

end

