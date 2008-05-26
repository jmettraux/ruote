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

require 'json' # gem 'json_pure'

require 'openwfe/util/xml'
require 'openwfe/expressions/flowexpression'


#
# 'f', 'q' and 'v' expressions
#
# 'a' as well
#

module OpenWFE

    #
    # This expression implementation gathers the 'f', 'q' and 'v' expressions,
    # along with their fullname 'field', 'variable' and 'quote'.
    #
    # These expressions place the value of the corresponding, field, variable
    # or quoted (direct value) in the 'result' field of the current workitem.
    #
    #     sequence do
    #
    #         set :field => "f0", :value => "fox"
    #         set :variable => "v0", :value => "vixen"
    #
    #         set :field => "f1" do
    #             v "v0"
    #         end
    #         set :variable => "v1" do
    #             f "f0"
    #         end
    #         set :variable => "v2" do
    #             f "f0"
    #         end
    #     end
    #
    # Well, this is perhaps not the best example.
    #
    class FqvExpression < FlowExpression

        names :f, :q, :v, :field, :quote, :variable

        #
        # apply / reply

        def apply (workitem)

            name = @fei.expression_name[0, 1]
            text = fetch_text_content workitem

            method = MAP[name]

            result = self.send method, text, workitem

            workitem.set_result(result) if result != nil

            reply_to_parent workitem
        end

        protected

            MAP = {
                "f" => :field,
                "q" => :quote,
                "v" => :variable
            }

            def field (text, workitem)
                workitem.attributes[text]
            end

            def quote (text, workitem)
                text
            end

            def variable (text, workitem)
                self.lookup_variable(text)
            end
    end

    #
    # The 'a' or 'attribute' expression. Directly describing some
    # variable or list content in XML or in YAML.
    #
    #     _set :field => "list" do
    #         _a """
    #             <array>
    #                 <string>a</string>
    #                 <string>b</string>
    #                 <number>3</number>
    #                 <string>d</string>
    #                 <null/>
    #                 <false/>
    #                 <string>it's over</string>
    #             </array>
    #         """
    #     end
    #
    # or
    #
    #     _set :field => "list" do
    #         _attribute """
    #     ---
    #     - a
    #     - b
    #     - c
    #         """
    #      end
    #
    # Note that it's actually easier to write :
    #
    #     _set :field => "list" do
    #         reval "[ 'a', 'b', 'c' ]"
    #     end
    #
    # but it's less secure. The best way might be :
    #
    #     set :field => "list", :value => [ 'a', 'b', 'c' ]
    #
    # Yet another way, as this <a> expression accepts JSON :
    #
    #     set :field => 'list' do
    #         a '[1,2,false,"my name"]'
    #     end
    #
    #
    class AttributeExpression < FlowExpression

        names :a, :attribute

        XML_REGEX = /<.*>/


        def apply (workitem)

            child = @children.first

            text = if child.is_a?(String)

                #child
                fetch_text_content workitem

            elsif child.is_a?(FlowExpressionId)

                exp = get_expression_pool.fetch_expression child
                ExpressionTree.to_s exp.raw_representation

            else

                child.to_s
            end

            text = text.strip

            result = if text[0, 3] == '---'

                from_yaml text

            elsif text.match(XML_REGEX)

                from_xml text
            end

            result = from_json(text) if result == nil

            workitem.set_result(result) if result != nil

            reply_to_parent workitem
        end

        protected

            def from_yaml (text)

                begin

                    YAML.load text

                rescue Exception => e
                    linfo { "from_yaml() failed : #{e}" }
                    nil
                end
            end

            def from_xml (text)

                begin

                    OpenWFE::Xml.from_xml text

                rescue Exception => e
                    linfo { "from_xml() failed : #{e}" }
                    nil
                end
            end

            def from_json (text)

                begin

                    JSON.parse text

                rescue Exception => e
                    linfo { "from_json() failed : #{e}" }
                    nil
                end
            end
    end

end

