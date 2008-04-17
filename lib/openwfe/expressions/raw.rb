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

require 'openwfe/exceptions'
require 'openwfe/expressions/flowexpression'
require 'openwfe/rudefinitions'


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
        def self.new_raw (
            fei, parent_id, env_id, app_context, raw_representation)

            re = self.new

            re.fei = fei
            re.parent_id = parent_id
            re.environment_id = env_id
            re.application_context = app_context
            re.attributes = nil
            re.children = []
            re.apply_time = nil

            re.raw_representation = raw_representation
            re
        end

        #--
        # A duplication method that duplicates everything, except
        # the application context
        #
        #def dup
        #    self.class.new_raw(
        #        @fei.dup,
        #        @parent_id ? @parent_id.dup : nil,
        #        @environment_id ? @environment_id.dup : nil,
        #        @application_context,
        #        raw_representation)
        #end
        #alias :fulldup :dup
        #++

        def instantiate_real_expression (
            workitem, exp_name=nil, exp_class=nil, attributes=nil)

            exp_name ||= expression_name
            exp_class ||= expression_class

            raise "unknown expression '#{exp_name}'" \
                unless exp_class

            #ldebug do 
            #    "instantiate_real_expression() exp_class is #{exp_class}"
            #end

            attributes ||= raw_representation[1]

            exp = exp_class.new
            exp.fei = @fei 
            exp.parent_id = @parent_id
            exp.environment_id = @environment_id
            exp.application_context = @application_context
            exp.attributes = attributes

            exp.raw_representation = raw_representation
            exp.raw_rep_updated = raw_rep_updated
                #
                # keeping track of how the expression look at apply / 
                # instantiation time

            consider_tag workitem, exp
            
            handle_descriptions

            exp.children = extract_children \
                unless exp_class.uses_template? 

            exp
        end

        #
        # When a raw expression is applied, it gets turned into the
        # real expression which then gets applied.
        #
        def apply (workitem)

            exp_name, exp_class, attributes = determine_real_expression

            expression = instantiate_real_expression(
                workitem, exp_name, exp_class, attributes)

            expression.apply_time = Time.now
            expression.store_itself

            expression.apply workitem
        end

        #
        # This method is called by the expression pool when it is about
        # to launch a process, it will interpret the 'parameter' statements
        # in the process definition and raise an exception if the requirements
        # are not met.
        #
        def check_parameters (workitem)

            extract_parameters.each do |param|
                param.check(workitem)
            end
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

            raw_representation[1]['name'].to_s
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
        def extract_attributes

            raw_representation[1]
        end
        
        protected

            #
            # looks up a participant in the participant map, considers
            # "my-participant" and "my_participant" as the same
            # (by doing two lookups).
            #
            def lookup_participant (name)

                p = get_participant_map.lookup_participant(name)

                unless p
                    name = OpenWFE::to_underscore(name)
                    p = get_participant_map.lookup_participant(name)
                end

                return name if p

                nil
            end

            #
            # Determines if this raw expression points to a classical 
            # expression, a participant or a subprocess, or nothing at all...
            #
            def determine_real_expression

                exp_name = expression_name()
                exp_class = expression_class()
                var_value = lookup_variable exp_name
                attributes = extract_attributes

                unless var_value
                    #
                    # accomodating "sub_process_name" and "sub-process-name"
                    #
                    alt = OpenWFE::to_underscore exp_name
                    var_value = lookup_variable(alt) if alt != exp_name

                    exp_name = alt if var_value
                end

                var_value = exp_name \
                    if (not exp_class and not var_value)

                if var_value.is_a?(String)

                    participant_name = lookup_participant var_value

                    if participant_name
                        exp_name = participant_name
                        exp_class = ParticipantExpression
                        attributes['ref'] = participant_name
                    end

                elsif var_value.is_a?(FlowExpressionId) \
                    or var_value.is_a?(RawExpression)

                    exp_class = SubProcessRefExpression
                    attributes['ref'] = exp_name
                end
                # else, it's a standard expression

                [ exp_name, exp_class, attributes ]
            end

            #
            # Takes care of extracting the process definition descriptions
            # if any and to set the description variables accordingly.
            #
            def handle_descriptions

                default = false

                ds = extract_descriptions

                ds.each do |k, description|
                    vname = if k == "default"
                        default = true
                        "description"
                    else
                        "description__#{k}"
                    end
                    set_variable vname, description.to_s
                end

                return if ds.length < 1

                set_variable "description", ds[0][1].to_s \
                    unless default
            end

            def extract_descriptions

                result = []
                raw_representation.last.each do |child|

                    #next unless child.is_a?(SimpleExpRepresentation)
                    next if is_not_a_node?(child)
                    next if child.first.intern != :description

                    attributes = child[1]

                    lang = attributes[:language]
                    lang = attributes[:lang] unless lang
                    lang = "default" unless lang

                    result << [ lang, child.last.first ]
                end
                result
            end

            def extract_children

                i = 0
                result = []
                raw_representation.last.each do |child|

                    #if child.kind_of?(SimpleExpRepresentation)
                    #if child.kind_of?(Array)
                    if is_not_a_node?(child)

                        result << child
                    else

                        cname = child.first.intern

                        next if cname == :param
                        next if cname == :parameter
                        next if cname == :description

                        cfei = @fei.dup
                        cfei.expression_name = child.first
                        cfei.expression_id = "#{cfei.expression_id}.#{i}"

                        efei = @environment_id

                        rawexp = RawExpression.new_raw(
                            cfei, @fei, efei, @application_context, child)

                        get_expression_pool.update rawexp

                        i = i + 1

                        result << rawexp.fei
                    end
                end
                result
            end

            def extract_parameters

                r = []
                raw_representation.last.each do |child|

                    #next unless child.is_a?(SimpleExpRepresentation)
                    #next unless child.is_a?(Array)
                    next if is_not_a_node?(child)

                    name = child.first.to_sym
                    next unless (name == :parameter or name == :param)

                    attributes = child[1]

                    r << Parameter.new(
                        attributes['field'],
                        attributes['match'],
                        attributes['default'],
                        attributes['type'])
                end
                r
            end

            def is_not_a_node? (child)

                (( ! child.is_a?(Array)) || 
                 child.size != 3 ||
                 ( ! child.first.is_a?(String)))
            end

            #
            # Expressions can get tagged. Tagged expressions can easily
            # be cancelled (undone) or redone.
            #
            def consider_tag (workitem, new_expression)

                tagname = new_expression.lookup_string_attribute :tag, workitem

                return unless tagname

                ldebug { "consider_tag() tag is '#{tagname}'" }

                set_variable tagname, Tag.new(self, workitem)
                    #
                    # keep copy of raw expression and workitem as applied

                new_expression.attributes["tag"] = tagname
                    #
                    # making sure that the value of tag doesn't change anymore
            end

            #
            # A small class wrapping a tag (a raw expression and the workitem
            # it received at apply time.
            #
            class Tag

                attr_reader \
                    :raw_expression,
                    :workitem

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
            # Encapsulating 
            #     <parameter field="x" default="y" type="z" match="m" />
            #
            # Somehow I have that : OpenWFEru is not a strongly typed language
            # ... Anyway I implemented that to please Pat.
            #
            class Parameter

                def initialize (field, match, default, type)

                    @field = to_s field
                    @match = to_s match
                    @default = to_s default
                    @type = to_s type
                end

                #
                # Will raise an exception if this param requirement is not
                # met by the workitem.
                #
                def check (workitem)

                    unless @field
                        raise \
                            OpenWFE::ParameterException,
                            "'parameter'/'param' without a 'field' attribute"
                    end

                    field_value = workitem.attributes[@field]
                    field_value = @default unless field_value

                    unless field_value
                        raise \
                            OpenWFE::ParameterException, 
                            "field '#{@field}' is missing" \
                    end

                    check_match(field_value)

                    enforce_type(workitem, field_value)
                end

                protected

                    #
                    # Used in the constructor to flatten everything to strings.
                    #
                    def to_s (o)
                        return nil unless o
                        o.to_s
                    end

                    #
                    # Will raise an exception if it cannot coerce the type
                    # of the value to the one desired.
                    #
                    def enforce_type (workitem, value)

                        value = if not @type
                            value
                        elsif @type == "string"
                            value.to_s
                        elsif @type == "int" or @type == "integer"
                            Integer(value)
                        elsif @type == "float"
                            Float(value)
                        else
                            raise 
                                "unknown type '#{@type}' for field '#{@field}'"
                        end

                        workitem.attributes[@field] = value
                    end

                    def check_match (value)

                        return unless @match

                        unless value.to_s.match(@match)
                            raise \
                                OpenWFE::ParameterException,
                                "value of field '#{@field}' doesn't match"
                        end
                    end
            end
    end

    #
    # This class is only present to ensure that OpenWFEru 0.9.17 can read
    # previous (<= 0.9.16) expools.
    #
    class ProgRawExpression < RawExpression

        def raw_representation

            @raw_representation.to_a
        end
    end

    #
    # This class is only present to ensure that OpenWFEru 0.9.17 can read
    # previous (<= 0.9.16) expools.
    #
    class XmlRawExpression < RawExpression

        def raw_representation

            #SimpleExpRepresentation.from_xml @raw_representation_s
            DefParser.parse_xml @raw_representation_s
        end
    end

    #
    # This class is only present to ensure that OpenWFEru 0.9.17 can read
    # previous (<= 0.9.16) expools.
    #
    class SimpleExpRepresentation

        def to_a

            children = @children.collect do |c|
                if c.is_a?(SimpleExpRepresentation)
                    c.to_a
                else
                    c
                end
            end

            a = [ @name, @attributes, children ]
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

            return "_" + method_name \
                if KEYWORDS.include? eval(":"+method_name)

            method_name
        end

        def OpenWFE.to_expression_name (method_name)

            method_name = method_name.to_s
            method_name = method_name[1..-1] if method_name[0, 1] == "_"
            method_name = OpenWFE::to_dash(method_name)
            method_name
        end

end

