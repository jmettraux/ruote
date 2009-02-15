#
#--
# Copyright (c) 2006-2009, John Mettraux, Nicolas Modrzyk OpenWFE.org
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
# Nicolas Modrzyk at openwfe.org
#

module OpenWFE

  #
  # This mixin helds an application_context field and provides a
  # lookup method for digging into that context.
  #
  module Contextual

    attr_accessor :application_context

    alias :ac :application_context

    #
    # Looks up something in the application context, if the given
    # key is a class, then the first value in the context of that
    # class is returned.
    #
    def lookup (key)

      if key.kind_of?(Class)
        @application_context.each do |k, value|
          return value if value.class == key
        end
        return nil
      end

      @application_context[key]
    end

    #
    # Use reflection to instantiate the new service,and
    # add it to the application context
    # The service_name can be a String or a Symbol (which will be
    # turned into a String).
    #
    def init_service (service_name, service_class)

      if service_name
        #
        # if there is a service previously registered under the same name,
        # make sure to stop before it gets 'overriden' in the
        # application context

        s = @application_context[service_name]
        s.stop if s.respond_to?(:stop)
      end

      s = service_class.new(service_name, @application_context)

      unless service_name
        #
        # making sure to register the service. service#new doesn't
        # register when there is no service_name

        s.service_name = "#{service_class.name}::#{s.object_id}"
        @application_context[s.service_name.to_s] = s
      end

      s
    end

    #
    # Returns the work directory for the OpenWFE[ru] application context
    # (if any).
    #
    def get_work_directory (context_or_dir=nil)

      dir = if context_or_dir.is_a?(String)
        context_or_dir
      elsif context_or_dir.respond_to?(:[])
        context_or_dir[:work_directory]
      else
        @application_context[:work_directory] if @application_context
      end

      dir = DEFAULT_WORK_DIRECTORY unless dir

      FileUtils.makedirs(dir) unless File.exist?(dir)

      dir
    end

  end

end
