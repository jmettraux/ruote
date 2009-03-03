#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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

    def initialize (
      endpoint_url, namespace, method_name, params, param_prefix='')

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
        get_param(workitem, param)
      end
    end

    #
    # This implementation simply stuffs the result into the workitem
    # as an attribute named "__result__".
    #
    # Feel free to override this method.
    #
    def handle_call_result (result, workitem)

      workitem.set_result(result)
    end

    protected

      def get_param (workitem, param_name)

        param_name = @param_prefix + param_name if @param_prefix

        workitem.attributes[param_name] || ''
      end

  end

end

