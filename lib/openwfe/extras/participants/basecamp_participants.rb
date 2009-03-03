#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
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


require 'openwfe/participants/participants'
require 'openwfe/extras/misc/basecamp'


module OpenWFE
module Extras

  class BasecampParticipant
    include OpenWFE::LocalParticipant
    include OpenWFE::TemplateMixin

    def initialize (params, &block)

      super()

      @template = params[:template]
      @block_template = block

      @company_id = params[:company_id]
      #@project_id = params[:project_id]

      @responsible_party_id = params[:responsible_party_id]
      @todo_list_id = params[:todo_list_id]

      ssl = params[:ssl]
      ssl = true if ssl == nil

      @camp = Basecamp.new(
        params[:host], params[:username], params[:password], ssl)
    end

    def consume (workitem)

      text = workitem['todo_text'] || eval_template(wi)

      resp = workitem['todo_responsible_party'] || @responsible_party_id
      list = workitem['toto_list_id'] || @todo_list_id

      todo = @camp.create_item list, text, resp

      workitem['todo_id'] = todo.id

      reply_to_engine workitem
    end
  end
end
end

