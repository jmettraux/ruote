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

require 'rufus/dollar' # gem 'rufus-dollar'

require 'openwfe/utils'
require 'openwfe/util/treechecker'


module OpenWFE

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

    r[dosub(k, flow_expression, workitem)] =
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

    pr, k = extract_prefix key

    # stage 0

    v = lookup(pr[0, 1], k)
    return v if v != nil

    # stage 1

    return '' if pr.size < 2

    lookup(pr[1, 1], k)
  end

  def []= (key, value)

    pr, k = extract_prefix key
    pr = pr[0, 1]

    if pr == 'f'

    @workitem.set_attribute k, value

    elsif @flow_expression

    @flow_expression.set_variable k, value
    end
  end

  def has_key? (key)

    pr, k = extract_prefix key

    return true if pr == 'r'

    (self[key] != nil)
  end

  protected

    def lookup (pr, key)

    case pr
      when 'v' then @flow_expression.lookup_variable(key)
      when 'f' then @workitem.lookup_attribute(key)
      when 'r' then call_ruby(key)
      else nil
    end
    end

    def extract_prefix (key)

    i = key.index(':')

    return [ @default_prefix, key ] if not i

    pr = key[0..i-1] # until ':'
    pr = pr[0, 2] # the first two chars

    pr = pr[0, 1] unless (pr == 'vf') or (pr == 'fv')

    [ pr, key[i+1..-1] ]
    end

    #--
    #def call_function (function_name)
    #  #"function '#{function_name}' is not implemented"
    #  "functions are not yet implemented"
    #  #
    #  # no need for them... we have Ruby :)
    #end
    #++

    #
    # The ${r:1+2} stuff. ("3").
    #
    def call_ruby (ruby_code)

      #if @flow_expression and @flow_expression.ac[:ruby_eval_allowed] != true
      #  return ''
      #end
      return '' if @flow_expression.ac[:ruby_eval_allowed] != true

      wi = @workitem
      workitem = @workitem

      #fexp = nil
      #flow_expression = nil
      #fei = nil

      #if @flow_expression
      fexp = @flow_expression
      flow_expression = @flow_expression
      fei = @flow_expression.fei
      #end
        #
        # some simple notations made available to ${ruby:...}
        # notations

      #TreeChecker.check ruby_code
      fexp.ac[:s_tree_checker].check(ruby_code)

      eval(ruby_code, binding()).to_s
    end
  end

end

