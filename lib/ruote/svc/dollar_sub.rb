#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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
require 'ruote/svc/treechecker'


module Ruote

  #
  # This service is in charge of extrapolating strings like
  # "${f:nada} == ${f:y}".
  #
  # It relies on the rufus-dollar gem.
  #
  # It's OK to override this service with your own.
  #
  class DollarSubstitution

    def initialize(context)

      @context = context
    end

    # Performs 'dollar substitution' on a piece of text with as input
    # a flow expression and a workitem (fields and variables).
    #
    # With help from Nick Petrella (2008/03/20)
    #
    def s(text, flow_expression, workitem)

      if text.is_a?(String)

        literal_sub(
          Rufus.dsub(text, dict_class.new(flow_expression, workitem)),
          flow_expression,
          workitem)

      elsif text.is_a?(Array)

        text.collect { |e| s(e, flow_expression, workitem) }

      elsif text.is_a?(Hash)

        text.remap { |(k, v), h|
          h[s(k, flow_expression, workitem)] = s(v, flow_expression, workitem)
        }

      else

        text
      end
    end

    # This method is public, for easy overriding. This implementation returns
    # Ruote::Dollar::Dict whose instances are used to extrapolate dollar
    # strings like "${f:customer}" or "${r:Time.now.to_s}/${f:year_target}"
    #
    def dict_class

      ::Ruote::Dollar::Dict
    end

    protected

    # If the final text is of the form "$f:x" or "$v:y" will lookup the
    # x field or the y variable. If the lookup is successful (not nil) will
    # return the value, not the text (the value.to_s).
    #
    def literal_sub(s, fexp, wi)

      case s
        when /^\$(?:variable|var|v):([^{}\s\$]+)$/
          fexp.lookup_variable($~[1])
        when /^\$([^{}:\s\$]+)$/, /^\$(?:field|fld|f):([^{}\s\$]+)$/
          Ruote.lookup(wi['fields'], $~[1])
        else
          s
      end
    end
  end

  #
  # A mini-namespace Ruote::Dollar for Dict and RubyContext, just to separate
  # them from the rest of Ruote.
  #
  module Dollar

    #
    # Wrapping a flow expression and the current workitem as a
    # Hash-like object ready for lookup at substitution time.
    #
    class Dict

      attr_reader :fexp
      attr_reader :workitem

      def initialize(flow_expression, workitem)

        @fexp = flow_expression
        @workitem = workitem
      end

      def [](key)

        return @fexp.fei.to_storage_id if key == 'fei'
        return @fexp.fei.wfid if key == 'wfid'
        return @fexp.fei.subid if key == 'subid'
        return @fexp.fei.subid if key == 'sub_wfid' # deprecated in 2.1.12
        return @fexp.fei.expid if key == 'expid'
        return @fexp.fei.engine_id if key == 'engine_id'
        return @fexp.fei.mnemo_id if key == 'mnemo_id'

        return @workitem['fields']['__tags__'] if key == 'tags'
        return (@workitem['fields']['__tags__'] || []).last if key == 'tag'
        return (@workitem['fields']['__tags__'] || []).join('/') if key == 'full_tag'

        pr, k = extract_prefix(key)

        # stage 0

        v = lookup(pr[0, 1], k)

        return v if v != nil

        # stage 1

        return '' if pr.size < 2

        lookup(pr[1, 1], k)
      end

      def []=(key, value)

        pr, k = extract_prefix(key)
        pr = pr[0, 1]

        if pr == 'f'

          @workitem.set_attribute(k, value)

        elsif @fexp

          @fexp.set_variable(k, value)
        end
      end

      def has_key?(key)

        pr, k = extract_prefix(key)

        return true if pr == 'r'

        (self[key] != nil)
      end

      protected

      def lookup(pr, key)

        case pr
          when 'v' then @fexp.lookup_variable(key)
          when 'f' then Ruote.lookup(@workitem['fields'], key)
          when 'r' then ruby_eval(key)
          else nil
        end
      end

      def extract_prefix(key)

        i = key.index(':')

        return [ 'f', key ] if not i
          # 'f' is the default prefix (field, not variable)

        pr = key[0..i-1] # until ':'
        pr = pr[0, 2] # the first two chars

        pr = pr[0, 1] unless (pr == 'vf') or (pr == 'fv')

        [ pr, key[i+1..-1] ]
      end

      # TODO : rdoc me
      #
      def ruby_eval(ruby_code)

        raise ArgumentError.new(
          "'ruby_eval_allowed' is set to false, cannot evaluate >" +
          ruby_code +
          "< (http://ruote.rubyforge.org/dollar.html)"
        ) if @fexp.context['ruby_eval_allowed'] != true

        @fexp.context.treechecker.dollar_check(ruby_code)

        RubyContext.new(self).instance_eval(ruby_code)
      end
    end

    # Dict uses this RubyContext class to evaluate ruby code. The method
    # of this instance are directly visible to "${r:ruby_code}" ruby code.
    #
    class RubyContext < Ruote::BlankSlate

      attr_reader :workitem

      def initialize(dict)

        @dict = dict
        @workitem = Ruote::Workitem.new(@dict.workitem)
      end

      # The FlowExpression for which the rendering/substitution is occurring.
      #
      def flow_expression

        @dict.fexp
      end

      alias fe flow_expression
      alias fexp flow_expression

      # The FlowExpressionId of the expression for which the
      # rendering/substitution is occurring.
      #
      def fei

        @dict.fexp.fei
      end

      alias wi workitem

      # The engine_id, if any.
      #
      def engine_id

        @dict.fexp.context.engine_id
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
      def d(s)

        Rufus.dsub("${#{s}}", @dict)
      end

      # Given a workitem with the field "newspaper" set to "NYT",
      # "${r:newspaper}" will eval to "NYT".
      #
      # If the field "cars" hold the value [ "bmw", "volkswagen" ],
      # "${r:cars[0]}" will eval to "bmw".
      #
      # Else the regular NoMethodError will be raised.
      #
      def method_missing(m, *args)

        if args.length < 1 && v = @workitem.fields[m.to_s]
          return v
        end

        super
      end
    end
  end
end

