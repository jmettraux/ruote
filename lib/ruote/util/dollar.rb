#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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


require 'rufus/dollar' # gem 'rufus-dollar'
require 'ruote/util/lookup'
require 'ruote/util/treechecker'


module Ruote

  # Performs 'dollar substitution' on a piece of text with as input
  # a flow expression and a workitem (fields and variables).
  #
  def self.dosub (text, flow_expression, workitem)

    #
    # patch by Nick Petrella (2008/03/20)
    #

    if text.is_a?(String)

      Rufus.dsub(text, FlowDict.new(flow_expression, workitem))

    elsif text.is_a?(Array)

      text.collect { |e| dosub(e, flow_expression, workitem) }

    elsif text.is_a?(Hash)

      text.inject({}) do |h, (k, v)|

        h[dosub(k, flow_expression, workitem)] =
          dosub(v, flow_expression, workitem)
        h
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

    def initialize (flow_expression, workitem, default_prefix='f')

      @fexp = flow_expression
      @workitem = workitem
      @default_prefix = default_prefix
    end

    def [] (key)

      return @fexp.fei.to_storage_id if key == 'fei'
      return @fexp.fei.wfid if key == 'wfid'
      return @fexp.fei.sub_wfid if key == 'sub_wfid'
      return @fexp.fei.expid if key == 'expid'

      pr, k = extract_prefix(key)

      # stage 0

      v = lookup(pr[0, 1], k)

      return v if v != nil

      # stage 1

      return '' if pr.size < 2

      lookup(pr[1, 1], k)
    end

    def []= (key, value)

      pr, k = extract_prefix(key)
      pr = pr[0, 1]

      if pr == 'f'

        @workitem.set_attribute(k, value)

      elsif @fexp

        @fexp.set_variable(k, value)
      end
    end

    def has_key? (key)

      pr, k = extract_prefix(key)

      return true if pr == 'r'

      (self[key] != nil)
    end

    protected

    def lookup (pr, key)

      case pr
        when 'v' then @fexp.lookup_variable(key)
        when 'f' then Ruote.lookup(@workitem['fields'], key)
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

    # The ${r:1+2} stuff. ("3").
    #
    def call_ruby (ruby_code)

      return '' if @fexp.context['ruby_eval_allowed'] != true

      engine_id = @fexp.context.engine_id

      wi = Ruote::Workitem.new(@workitem)
      workitem = wi

      fe = @fexp
      fexp = @fexp
      flow_expression = @fexp
      fei = @fexp.fei
        #
        # some simple notations made available to ${ruby:...}
        # notations

      @fexp.context.treechecker.check(ruby_code)

      # clear for eval...

      eval(ruby_code, binding()).to_s
    end

    # This 'd' function can be called from inside ${r:...} notations.
    #
    #   pdef = Ruote.process_definition do
    #     sequence do
    #       set 'f:toto' => 'person'
    #       echo "${r:d('f:toto')}"
    #     end
    #   end
    #
    # will yield "person".
    #
    def d (s)

      Rufus.dsub("${#{s}}", self)
    end
  end
end

