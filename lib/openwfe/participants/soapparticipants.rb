#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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

require 'soap/rpc/driver'

require 'openwfe/participants/participant'


module OpenWFE

  #
  # Wrapping a simple web service call within an OpenWFEru participant.
  #
  #   quote_service = OpenWFE::SoapParticipant.new(
  #     "http://services.xmethods.net/soap",    # service URI
  #     "urn:xmethods-delayed-quotes",        # namespace
  #     "getQuote",                 # operation name
  #     [ "symbol" ])                 # param arrays (workitem fields)
  #
  #   engine.register_participant("quote_service", quote_service)
  #
  # By default, call params for the SOAP operations are determined by
  # iterating the parameters and fetching the values under the
  # corresponding workitem fields.
  # This behaviour can be changed by overriding the prepare_call_params()
  # method.
  #
  # On the return side, you can override the method handle_call_result
  # for better mappings between web service calls and the workitems.
  #
  class SoapParticipant
    include LocalParticipant

    def initialize \
      (endpoint_url, namespace, method_name, params, param_prefix="")

      super()

      @driver = SOAP::RPC::Driver.new(endpoint_url, namespace)

      @method_name = method_name
      @params = params
      @param_prefix = param_prefix

      @driver.add_method(method_name, *params)
    end

    #
    # The method called by the engine when the flow reaches an instance
    # of this Participant class.
    #
    def consume (workitem)

      call_params = prepare_call_params(workitem)

      call_result = @driver.send(@method_name, *call_params)

      handle_call_result(call_result, workitem)

      reply_to_engine(workitem)
    end

    #
    # The base implementation : assumes that for each webservice operation
    # param there is a workitem field with the same name.
    #
    # Feel free to override this method.
    #
    def prepare_call_params (workitem)

      @params.collect do |param|
        get_param workitem, param
      end
    end

    #
    # This implementation simply stuffs the result into the workitem
    # as an attribute named "__result__".
    #
    # Feel free to override this method.
    #
    def handle_call_result (result, workitem)

      workitem.attributes["__result__"] = result
    end

    protected

      def get_param (workitem, param_name)

        param_name = @param_prefix + param_name if @param_prefix

        workitem.attributes[param_name] || ""
      end

  end

end

