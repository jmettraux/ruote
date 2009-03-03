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


#require 'json' # gem 'json_pure'

require 'openwfe/util/xml'
require 'openwfe/util/json'
require 'openwfe/expressions/flowexpression'


module OpenWFE

  #
  # This expression implementation gathers the 'f', 'q' and 'v' expressions,
  # along with their fullname 'field', 'variable' and 'quote'.
  #
  # These expressions place the value of the corresponding, field, variable
  # or quoted (direct value) in the 'result' field of the current workitem.
  #
  #   sequence do
  #
  #     set :field => "f0", :value => "fox"
  #     set :variable => "v0", :value => "vixen"
  #
  #     set :field => "f1" do
  #       v "v0"
  #     end
  #     set :variable => "v1" do
  #       f "f0"
  #     end
  #     set :variable => "v2" do
  #       f "f0"
  #     end
  #   end
  #
  # Well, this is perhaps not the best example.
  #
  class FqvExpression < FlowExpression

    names :f, :q, :v, :field, :quote, :variable

    #
    # apply / reply

    def apply (workitem)

      name = @fei.expression_name[0, 1]
      text = fetch_text_content(workitem)

      method = MAP[name]

      result = self.send method, text, workitem

      workitem.set_result(result) if result != nil

      reply_to_parent workitem
    end

    protected

      MAP = {
        'f' => :field,
        'q' => :quote,
        'v' => :variable
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
  # variable or list content in XML, YAML or JSON.
  #
  #   _set :field => "list" do
  #     _a """
  #       <array>
  #         <string>a</string>
  #         <string>b</string>
  #         <number>3</number>
  #         <string>d</string>
  #         <null/>
  #         <false/>
  #         <string>it's over</string>
  #       </array>
  #     """
  #   end
  #
  # or
  #
  #   _set :field => "list" do
  #     _attribute """
  #   ---
  #   - a
  #   - b
  #   - c
  #     """
  #    end
  #
  # Note that it's actually easier to write :
  #
  #   _set :field => "list" do
  #     reval "[ 'a', 'b', 'c' ]"
  #   end
  #
  # but it's less secure. The best way might be :
  #
  #   set :field => "list", :value => [ 'a', 'b', 'c' ]
  #
  # Yet another way, as this <a> expression accepts JSON :
  #
  #   set :field => 'list' do
  #     a '[1,2,false,"my name"]'
  #   end
  #
  # or
  #
  #   <process-definition name="test" revision="44b9">
  #     <set-fields>
  #       <a>{"customer":{"name":"Zigue","age":34},"approved":false}</a>
  #     </set-fields>
  #     <sequence>
  #       <print>${f:customer.name} (${f:customer.age}) ${f:approved}</print>
  #     </sequence>
  #   </process-definition>
  #
  #
  class AttributeExpression < FlowExpression

    names :a, :attribute

    XML_REGEX = /<.*>/


    def apply (workitem)

      child = raw_children.first

      text = if child.is_a?(String)

        fetch_text_content(workitem)

      elsif child.is_a?(Array)

        ExpressionTree.to_s(child)

      else

        child.to_s
      end

      text = text.strip

      result = if text[0, 3] == '---'

        from_yaml(text)

      elsif text.match(XML_REGEX)

        from_xml(text)
      end

      result = OpenWFE::Json::from_json(text) if result == nil
        # warning : if 'json' or 'active_support' are not present
        # from_json() will always return nil

      workitem.set_result(result) if result != nil

      reply_to_parent(workitem)
    end

    protected

      def from_yaml (text)

        begin

          YAML.load(text)

        rescue Exception => e
          linfo { "from_yaml() failed : #{e}" }
          nil
        end
      end

      def from_xml (text)

        begin

          OpenWFE::Xml.from_xml(text)

        rescue Exception => e
          linfo { "from_xml() failed : #{e}" }
          nil
        end
      end
  end

end

