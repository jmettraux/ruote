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


require 'openwfe/utils'


module OpenWFE

  #
  # This expression is used to launch/call a subprocess.
  #
  # For example :
  #
  #   <process-definition name="subtest0" revision="0">
  #     <sequence>
  #       <subprocess ref="sub0" a="A" b="B" c="C" />
  #       <sub0 a="A" b="B" c="C" />
  #     </sequence>
  #
  #     <process-definition name="sub0">
  #       <print>${a}${b}${c}</print>
  #     </process-definition>
  #
  #   </process-definition>
  #
  # It's totally OK to have URLs as referenced processes :
  #
  #   require 'openwfe/def'
  #
  #   class AnotherDefinition0 < OpenWFE::ProcessDefinition
  #     sequence do
  #       participant :ref => "toto"
  #       subprocess :ref => "http://company.process.server/def0.rb"
  #     end
  #   end
  #
  # (but the engine parameter :remove_definitions_allowed must be set to true,
  # as it's dangerous to fetch process definitions from other [untrusted]
  # hosts)
  #
  # The 'subprocess' expression accepts a 'forget' attribute :
  #
  #   class AnotherDefinition1 < OpenWFE::ProcessDefinition
  #     sequence do
  #       subprocess :ref => "my_subprocess", :forget => true
  #       participant :ref => "ringo"
  #     end
  #     process-definition :name => "my_subprocess" do
  #       participant :ref => "fake steve jobs"
  #     end
  #   end
  #
  # Note that a 'forgotten subprocess' will not have access to the variables
  # of its parent process.
  #
  # The 'subprocess' expression accepts an 'if' (or 'unless') attribute :
  #
  #   subprocess :ref => "interview_process", :if => "${f:screened}"
  #     # will trigger the subprocess only if the field screened
  #     # contains the string 'true' or the boolean 'true'
  #
  #   interview_process :if => "${f:screened}"
  #     # idem
  #
  #   interview_process :unless => "${f:has_had_problem_with_justice_?}"
  #     # well...
  #
  class SubProcessRefExpression < FlowExpression
    include ConditionMixin

    names :subprocess

    attr_accessor :subprocess_fei


    def apply (workitem)

      conditional = eval_condition(:if, workitem, :unless)

      return reply_to_parent(workitem) if conditional == false

      template = if self.respond_to?(:hint)

        hint

      else

        ref = lookup_ref(workitem)

        raise "'subprocess' expression misses a 'ref', 'field-ref' or 'variable-ref' attribute" unless ref

        OpenWFE::parse_known_uri(ref) || lookup_variable(ref)
      end

      raise "did not find any subprocess named '#{ref}'" unless template

      forget = lookup_boolean_attribute(:forget, workitem)

      params = lookup_attributes(workitem)

      text = fetch_text_content(workitem, false)
      params['0'] = text if text

      sub_fei = get_expression_pool.launch_subprocess(
        self, template, forget, workitem, params)

      if forget
        reply_to_parent(workitem.dup)
      else
        @subprocess_fei = sub_fei.dup
        store_itself # to keep track of @subprocess_fei
      end
    end

    # Takes care of cancelling the subprocess as well if any
    #
    def cancel

      trigger_on_cancel # if any

      return nil unless @subprocess_fei
      get_expression_pool.cancel(@subprocess_fei)
    end
  end

end

