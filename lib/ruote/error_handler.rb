#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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


module Ruote

  #
  # A ruote service for turning exceptions into process errors (or letting
  # those error fire any potential :on_error attributes in the process
  # definition).
  #
  # This service is used, by the worker, the dispatch pool and some
  # receivers (like the one in ruote-beanstalk).
  #
  class ErrorHandler

    def initialize (context)

      @context = context
    end

    # As used by the dispatch pool and the worker.
    #
    def msg_handle (msg, exception)

      fexp = Ruote::Exp::FlowExpression.fetch(
        @context, msg['fei'] || msg['workitem']['fei'])

      handle(msg, fexp, exception)
    end

    # As used by some receivers (see ruote-beanstalk's receiver).
    #
    def action_handle (action, fei, exception)

      fexp = Ruote::Exp::FlowExpression.fetch(@context, fei)

      msg = {
        'action' => action,
        'fei' => fei,
        'participant_name' => fexp.h.participant_name,
        'workitem' => fexp.h.applied_workitem }

      handle(msg, fexp, exception)
    end

    protected

    # As used by the worker.
    #
    def handle (msg, fexp, exception)

      wfid = msg['wfid'] || (msg['fei']['wfid'] rescue nil)
      fei = msg['fei'] || (fexp.h.fei rescue nil)

      backtrace = exception.backtrace || []

      # debug only

      if $DEBUG || ARGV.include?('-d')

        puts "\n== worker intercepted error =="
        puts
        p exception
        puts backtrace[0, 20].join("\n")
        puts "..."
        puts
        puts "-- msg --"
        msg.keys.sort.each { |k|
          puts "    #{k.inspect} =>\n#{msg[k].inspect}"
        }
        puts "-- . --"
        puts
      end

      # on_error ?

      return if fexp && fexp.handle_on_error(msg, exception)

      # emit 'msg'

      @context.storage.put_msg(
        'error_intercepted',
        'message' => exception.inspect,
        'wfid' => wfid,
        'msg' => msg)

      # fill error in the error journal

      @context.storage.put(
        'type' => 'errors',
        '_id' => "err_#{Ruote.to_storage_id(fei)}",
        'message' => exception.inspect,
        'trace' => backtrace.join("\n"),
        'fei' => fei,
        'msg' => msg
      ) if fei
    end
  end
end

