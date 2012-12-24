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

require 'rufus/json'


module Ruote

  #
  # Template rendering helper.
  #
  # (Currently only used by the SmtpParticipant, could prove useful for
  # custom participants)
  #
  # This module expects to find the ruote @context available (probably
  # accessible thanks to the Ruote::LocalParticipant module, see
  # Ruote::SmtpParticipant as an example).
  #
  module TemplateMixin

    # Do the rendering.
    #
    def render_template(template, flow_expression, workitem)

      template = (File.read(template) rescue nil) if is_a_file?(template)

      return render_default_template(workitem) unless template

      template = template.to_s
      workitem = workitem.to_h if workitem.respond_to?(:to_h)

      @context.dollar_sub.s(template, flow_expression, workitem)
    end

    # Simply returns a pretty-printed view of the workitem
    #
    def render_default_template(workitem)

      workitem = workitem.to_h if workitem.respond_to?(:to_h)

      s = []
      s << "workitem for #{workitem['participant_name']}"
      s << ''
      s << Rufus::Json.pretty_encode(workitem['fei'])
      s << ''
      workitem['fields'].keys.sort.each do |key|
        s << " - '#{key}'  ==>  #{Rufus::Json.encode(workitem['fields'][key])}"
      end
      s.join("\n")
    end

    protected

    def is_a_file?(s)

      return false unless s
      return false if s.index("\n")

      File.exist?(s)
    end
  end
end

