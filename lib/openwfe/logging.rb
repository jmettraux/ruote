#
#--
# Copyright (c) 2006-2008, John Mettraux, OpenWFE.org
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

        $OWFE_LOG.send level, &logblock
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

