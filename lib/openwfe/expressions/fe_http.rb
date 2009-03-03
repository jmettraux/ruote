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


require 'rufus/verbs'
require 'openwfe/expressions/flowexpression'
require 'openwfe/expressions/time'


module OpenWFE

  #
  # A module shared by the expression classes dealing with HTTP (ROA).
  #
  module HttpRequestPreparation

    protected

      def prepare_params (verb, workitem)

        uri =
          lookup_attribute(:uri, workitem) ||
          fetch_text_content(workitem)

        data = (verb == 'put' or verb == 'post') ?
          workitem.attributes['hdata'] : nil

        opts = workitem.attributes['hoptions'] || {}

        params = lookup_attributes workitem

        params['timeout'] = params['htimeout'] || params['hto']
          # the :timeout param is reserved for the poll timeout
          # not the http timeout

        params = params.merge opts

        params = params.inject({}) { |r, (k, v)| r[k.intern] = v; r }
          # 'symbolize' keys

        params[:uri] = uri
        params[:data] = data if data

        params
      end
  end

  #
  # The HTTP verbs as OpenWFEru (Ruote) expressions.
  #
  # Useful for basic RESTful BPM.
  #
  # This expression uses the rufus-verbs gem and accepts the exact
  # sames parameters (attributes) as this gem.
  #
  # see http://rufus.rubyforge.org/rufus-verbs
  #
  # some examples (in a ruby process definition) :
  #
  #   sequence do
  #
  #     get "http://server.example.com/res0.xml"
  #       # stores the XML content in the field 'rbody'
  #   end
  #
  class HttpExpression < FlowExpression
    include HttpRequestPreparation

    names :hpost, :hget, :hput, :hdelete


    def apply (workitem)

      verb = @fei.expression_name[1..-1]

      params = prepare_params verb, workitem

      # do it

      Thread.new do
        #
        # move execution out of process engine main thread
        # else would block other processes execution

        begin

          res = Rufus::Verbs.send verb, params

          workitem.hcode = res.code
          workitem.hheaders = res.to_hash
          workitem.hdata = res.body

        #rescue Timeout::Error => te
        #
        #  workitem.rerror = te.to_s
        #  workitem.rcode = -1

        rescue Exception => e

          linfo do
            "apply() #{verb.upcase} #{params[:uri]} failed : " +
            "#{e.to_s}"
          end

          workitem.hcode = -1
          workitem.herror = e.to_s
        end

        # over

        reply_to_parent workitem
      end
    end

    #def reply (workitem)
    #end

    #def cancel
    #   # kill thread ...
    #   nil
    #end

  end

  #
  # Polls repeatedly a web resource until a condition realizes.
  #
  # If there is no condition given, will be equivalent to 'hget'.
  #
  class HpollExpression < WaitingExpression
    include HttpRequestPreparation

    names :hpoll
    conditions :until

    attr_accessor :hparams


    def apply (workitem)

      @hparams = prepare_params 'get', workitem

      super
    end

    def trigger (params={})

      do_get unless params[:do_timeout!]

      super
    end

    protected

      def do_get

        ldebug { "do_get() #{@hparams.inspect}" }

        res = Rufus::Verbs.get @hparams

        @applied_workitem.hcode = res.code
        @applied_workitem.hheaders = res.to_hash
        @applied_workitem.hdata = res.body

      rescue Exception => e

        linfo do
          "do_get() #{verb.upcase} #{uri} failed : #{e.to_s}"
        end

        @applied_workitem.hcode = -1
        @applied_workitem.herror = e.to_s
      end
  end

end

