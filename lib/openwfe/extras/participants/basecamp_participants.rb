#
#--
# Copyright (c) 2008-2009, John Mettraux, OpenWFE.org
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

