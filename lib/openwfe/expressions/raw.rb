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


require 'openwfe/rudefinitions'
require 'openwfe/expressions/flowexpression'


module OpenWFE

  #
  # A class storing bits (trees) of process definitions just
  # parsed. Upon application (apply()) these raw expressions get turned
  # into real expressions.
  #
  class RawExpression < FlowExpression

    #
    # A [static] method for creating new RawExpression instances.
    #
    def self.new_raw (fei, parent_id, env_id, app_context, raw_tree)

      re = self.new

      re.fei = fei
      re.parent_id = parent_id
      re.environment_id = env_id
      re.application_context = app_context
      re.attributes = nil
      re.children = []
      re.apply_time = nil

      re.raw_representation = raw_tree
      re
    end

    #
    # When a raw expression is applied, it gets turned into the
    # real expression which then gets applied.
    #
    def apply (workitem)

      exp_class, val = determine_real_expression_class

      expression = instantiate_real_expression(workitem, exp_class, val)

      expression.apply_time = Time.now
      expression.store_itself

      expression.apply(workitem)
    end

    #--
    #def reply (workitem)
    # no implementation necessary
    #end
    #++

    def is_definition?

      get_expression_map.is_definition?(expression_name())
    end

    def expression_class

      get_expression_map.get_class(expression_name())
    end

    def definition_name

      (raw_representation[1]['name'] || raw_children.first).to_s
    end

    def expression_name

      raw_representation.first
    end

    #
    # Forces the raw expression to load the attributes and set them
    # in its @attributes instance variable.
    # Currently only used by FilterDefinitionExpression.
    #
    def load_attributes

      @attributes = raw_representation[1]
    end

    #
    # This method has been made public in order to have quick look
    # at the attributes of an expression before it's really
    # 'instantiated'.
    #
    # (overriden by ExpExpression)
    #
    def extract_attributes

      raw_representation[1]
    end

    #
    # This method is called by the expression pool when it is about
    # to launch a process, it will interpret the 'parameter' statements
    # in the process definition and raise an exception if the requirements
    # are not met.
    #
    def check_parameters (workitem)

      #extract_parameters.each { |param| param.check(workitem) }
      ExpressionTree.check_parameters(raw_representation, workitem)
    end

    protected

    #
    # Looks up a key as a variable or a participant.
    #
    def lookup (kind, key, underscore=false)

      val = (kind == :variable) ?
        lookup_variable(key) : get_participant_map.lookup_participant(key)

      return lookup(:participant, val) || lookup(:variable, val) \
        if kind == :variable and val.is_a?(String) # alias lookup

      return val, key if val

      return nil if underscore

      lookup(kind, OpenWFE::to_underscore(key), true)
    end

    #
    # Determines if this raw expression points to a classical
    # expression, a participant or a subprocess, or nothing at all...
    #
    def determine_real_expression_class

      exp_name = expression_name()

      val, key =
        lookup(:variable, exp_name) ||
        expression_class() ||
        lookup(:participant, exp_name)
          # priority to variables

      if val.is_a?(Array)

        [ SubProcessRefExpression, val ]

      elsif val.respond_to?(:consume)

        [ ParticipantExpression, key ]

      else

        [ val, nil ]
      end
    end

    def instantiate_real_expression (workitem, exp_class, val)

      raise "unknown expression '#{expression_name}'" unless exp_class

      exp = exp_class.new
      exp.fei = @fei
      exp.parent_id = @parent_id
      exp.environment_id = @environment_id
      exp.application_context = @application_context
      exp.attributes = extract_attributes()

      exp.raw_representation = @raw_representation
      exp.raw_rep_updated = @raw_rep_updated

      consider_tag(workitem, exp)
      consider_on_error(workitem, exp)
      consider_on_cancel(workitem, exp)

      if val
        class << exp
          attr_accessor :hint
        end
        exp.hint = val
      end # later sparing a variable/participant lookup

      exp
    end

    #
    # Expressions can get tagged. Tagged expressions can easily
    # be cancelled (undone) or redone.
    #
    def consider_tag (workitem, new_expression)

      tagname = new_expression.lookup_string_attribute(:tag, workitem)

      return unless tagname

      #ldebug { "consider_tag() tag is '#{tagname}'" }

      set_variable(tagname, Tag.new(self, workitem))
        #
        # keep copy of raw expression and workitem as applied

      new_expression.attributes['tag'] = tagname
        #
        # making sure that the value of tag doesn't change anymore
    end

    #
    # A small class wrapping a tag (a raw expression and the workitem
    # it received at apply time.
    #
    class Tag

      attr_reader :raw_expression, :workitem

      def flow_expression_id
        @raw_expression.fei
      end
      alias :fei :flow_expression_id

      def initialize (raw_expression, workitem)

        @raw_expression = raw_expression.dup
        @workitem = workitem.dup
      end
    end

    #
    # manages 'on-error' expression tags
    #
    def consider_on_error (workitem, new_expression)

      on_error = new_expression.lookup_string_attribute(:on_error, workitem)

      return unless on_error

      on_error = on_error.to_s

      handlers = lookup_variable('error_handlers') || []

      handlers << [ fei.dup, on_error ]
        # not using a hash to preserve insertion order
        # "deeper last"

      set_variable('error_handlers', handlers)

      new_expression.attributes['on_error'] = on_error
        #
        # making sure that the value of tag doesn't change anymore
    end

    #
    # manages 'on-cancel'
    #
    def consider_on_cancel (workitem, new_expression)

      on_cancel = new_expression.lookup_string_attribute(:on_cancel, workitem)

      return unless on_cancel

      new_expression.attributes['on_cancel'] = [ on_cancel, workitem.dup ]
        #
        # storing the on_cancel value (a participant name or a subprocess
        # name along with a copy of the workitem as applied among the
        # attributes of the new expression)
        #
        # (note 'on_cancel' and not 'on-cancel' as we're specifically storing
        # more info and not just the initial string value of the attribute)
    end
  end

  private

  #
  # OpenWFE process definitions do use some
  # Ruby keywords... The workaround is to put an underscore
  # just before the name to 'escape' it.
  #
  # 'undo' isn't reserved by Ruby, but lets keep it in line
  # with 'do' and 'redo' that are.
  #
  KEYWORDS = [
    :if, :do, :redo, :undo, :print, :sleep, :loop, :break, :when
    #:until, :while
  ]

  #
  # Ensures the method name is not conflicting with Ruby keywords
  # and turn dashes to underscores.
  #
  def OpenWFE.make_safe (method_name)

    method_name = OpenWFE::to_underscore(method_name)

    KEYWORDS.include?(method_name.to_sym) ? "_#{method_name}" : method_name
  end

  def OpenWFE.to_expression_name (method_name)

    method_name = method_name.to_s
    method_name = method_name[1..-1] if method_name[0, 1] == '_'
    method_name = OpenWFE::to_dash(method_name)
    method_name
  end

end

