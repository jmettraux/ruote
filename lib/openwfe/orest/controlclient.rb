#
#--
# Copyright (c) 2005-2007, John Mettraux, OpenWFE.org
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
# "hecho en Costa Rica"
#

require 'openwfe/orest/xmlcodec'
require 'openwfe/orest/restclient'
require 'openwfe/orest/definitions'


module OpenWFE

    #
    # This client is used to connect to an OpenWFE engine to call
    # 'control methods' for monitoring process instances, freezing or
    # cancelling them
    #
    class ControlClient < RestClient

        def initialize (url, username, password)

            super(url, username, password)
        end

        #
        # Returns the list of controlable expressions
        #
        def list_expressions ()

            r = self.get('listexpressions', nil, nil)
            decode(r)
        end

        #
        # Returns the list of expressions currently applied for a given
        # workflow instance
        #
        def get_flow_position (workflowInstanceId)

            params = {}
            params['id'] = workflowInstanceId

            r = self.get('getflowposition', nil, params)
            decode(r)
        end
        alias :get_flow_stack :get_flow_position

        #
        # Cancels a given expression (and potentially its whole subtree)
        #
        def cancel_expression (flowExpressionId)

            fei = OpenWFE.encode(flowExpressionId)

            params = {}

            decode(self.post('cancelexpression', nil, params, fei))
        end

        #
        # Freezes an expression (and potentially its whole subtree)
        #
        def freeze_expression (flowExpressionId)

            fei = OpenWFE.encode(flowExpressionId)

            params = {}

            decode(self.post('freezeexpression', nil, params, fei))
        end

        #
        # Unfreezes an expression (and potentially its whole subtree)
        #
        def unfreeze_expression (flowExpressionId)

            fei = OpenWFE.encode(flowExpressionId)

            params = {}

            decode(self.post('unfreezeexpression', nil, params, fei))
        end

    end

end

