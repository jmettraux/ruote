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

require 'openwfe/logging'
require 'openwfe/contextual'


module OpenWFE

  #
  # Most of the functionalities of an OpenWFEru service are implemented
  # here as a mixin. It's then easy to either extend Service or include
  # ServiceMixin, to compose an OpenWFEru service class.
  #
  module ServiceMixin

    include Contextual
    include Logging

    #
    # The name of the service
    #
    attr_accessor :service_name

    #
    # Inits the service by setting the service name and the application
    # context. Does also bind the service under the service name in the
    # application context.
    #
    def service_init (service_name, application_context)

      @service_name = service_name
      @application_context = application_context

      @application_context[@service_name] = self \
        if @service_name and @application_context
          #
          # don't register if it's not needed
    end

    #
    # Some services (like the scheduler one for example) need to
    # free some resources upon stopping. This can be achieved by
    # overwriting this method.
    #
    def stop
    end
  end

  #
  # A service has a service_name and a link to its application_context.
  # Via the application_context, it can lookup other services (if it
  # knows their names).
  #
  class Service
    include ServiceMixin

    def initialize (service_name, application_context)

      service_init(service_name, application_context)
    end
  end

  #def register (service)
  #  service.application_context[service.service_name] = service
  #  return service
  #end

end

