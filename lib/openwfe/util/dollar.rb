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

#require 'rubygems'
require 'rufus/dollar' # gem 'rufus-dollar'
require 'rufus/eval' # gem 'rufus-eval'

require 'openwfe/utils'

#
# 'dollar notation' implementation in Ruby
#

module OpenWFE

    DSUB_SAFETY_LEVEL = 4
        #
        # Ruby code ${ruby:...} will be evaluated with this
        # safety level.
        # (see http://www.rubycentral.com/book/taint.html )

    #
    # Performs 'dollar substitution' on a piece of text with as input
    # a flow expression and a workitem (fields and variables).
    #
    def OpenWFE.dosub (text, flow_expression, workitem)

        #
        # patch by Nick Petrella (2008/03/20)
        #

        if text.is_a?(String)

            Rufus::dsub(text, FlowDict.new(flow_expression, workitem))

        elsif text.is_a?(Array)

            text.collect { |e| dosub(e, flow_expression, workitem) }

        elsif text.is_a?(Hash)

            text.inject({}) do |r, (k, v)|

                r[dosub(k, flow_express, workitem)] = 
                    dosub(v, flow_expression, workitem)
                r
            end

        else

            text
        end
    end

    #
    # Wrapping a process expression and the current workitem as a
    # Hash object ready for lookup at substitution time.
    #
    class FlowDict

        def initialize (flow_expression, workitem, default_prefix='v')

            @flow_expression = flow_expression
            @workitem = workitem
            @default_prefix = default_prefix
        end

        def [] (key)

            p, k = extract_prefix(key)

            #puts "### p, k is '#{p}', '#{k}'"

            return '' if k == ''

            return @workitem.lookup_attribute(k) if p == 'f'

            if p == 'v'
                return '' unless @flow_expression
                return @flow_expression.lookup_variable(k)
            end

            #return call_function(k) if p == 'c'
            return call_ruby(k) if p == 'r'

            @workitem.lookup_attribute key
        end

        def []= (key, value)

            pr, k = extract_prefix(key)

            if pr == 'f'

                @workitem.set_attribute k, value

            elsif @flow_expression

                @flow_expression.set_variable k, value
            end
        end

        def has_key? (key)

            p, k = extract_prefix(key)

            return false if k == ''

            return @workitem.has_attribute?(k) if p == 'f'

            if p == 'v'
                return false unless @flow_expression
                return (@flow_expression.lookup_variable(k) != nil)
            end

            #return true if p == 'c'
            return true if p == 'r'

            @workitem.has_attribute?(key)
        end

        protected

            def extract_prefix (key)
                i = key.index(':')
                return @default_prefix, key if not i
                [ key[0..0], key[i+1..-1] ]
            end

            #--
            #def call_function (function_name)
            #    #"function '#{function_name}' is not implemented"
            #    "functions are not yet implemented"
            #        #
            #        # no need for them... we have Ruby :)
            #end
            #++

            def call_ruby (ruby_code)

                if @flow_expression
                    return "" \
                        if @flow_expression.ac[:ruby_eval_allowed] != true
                end

                #binding = nil
                #binding = @flow_expression.get_binding if @flow_expression
                #eval(ruby_code, binding).to_s

                wi = @workitem
                workitem = @workitem

                fexp = nil
                flow_expression = nil
                fei = nil

                if @flow_expression
                    fexp = @flow_expression
                    flow_expression = @flow_expression
                    fei = @flow_expression.fei
                end
                    #
                    # some simple notations made available to ${ruby:...}
                    # notations

                #eval(ruby_code, binding).to_s
                #eval(ruby_code).to_s

                Rufus::eval_safely(
                    ruby_code, DSUB_SAFETY_LEVEL, binding()).to_s
            end
    end

end

