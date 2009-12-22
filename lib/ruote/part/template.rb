#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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


module Ruote

  #
  # This mixin expects that the class that includes it has a @template
  # or a @block_template instance variable.
  #
  module TemplateMixin

    def render_template (flow_expression, workitem)

      template = if @block_template

        case @block_template.arity
          when 1 then @block_template.call(workitem)
          when 2 then @block_template.call(workitem, flow_expression)
          else @block_template.call(workitem, flow_expression, self)
        end

      elsif @template

        @template.is_a?(File) ? @template.read : @template.to_s

      else

        nil
      end

      raise(
        ArgumentError.new('no @template or @block_template found')
      ) unless template

      workitem = workitem.to_h if workitem.respond_to?(:to_h)

      Ruote.dosub(template, flow_expression, workitem)
    end
  end
end

