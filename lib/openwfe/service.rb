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

