#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
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

require 'ruote/part/local_participant'


module Ruote

  #
  # One of the simplest participants. Simply passes a workitem to a block
  # of ruby code.
  #
  #   engine.register_participant :alpha do |workitem|
  #     workitem.fields['time'] = Time.now
  #   end
  #
  # This participant implicitely replies to the engine when the block execution
  # is over.
  #
  # You can pass the flow_expression (participant expression) as well.
  #
  #   engine.register_participant :alpha do |workitem, flow_exp|
  #     workitem.fields['amount'] = flow_exp.lookup_variable('amount')
  #   end
  #
  #
  # == do_not_thread
  #
  # By default, this participant (like most other participants) is executed
  # in its own thread (in a Ruby runtime where EventMachine is running,
  # EM.next_tick is used instead of a new thread).
  #
  # You can change that behaviour (beware block thats monopolises the whole
  # engine !) by doing
  #
  #   alpha = engine.register_participant :alpha do |workitem|
  #     workitem.fields['time'] = Time.now
  #   end
  #
  #   alpha.do_not_thread = true
  #
  # (you could also override do_not_thread, the method ...)
  #
  class BlockParticipant

    include LocalParticipant

    attr_accessor :context

    def initialize (opts)

      @opts = opts
    end

    def do_not_thread

      @opts['do_not_thread']
    end

    def consume (workitem)

      block = @opts['block']

      @context.treechecker.block_check(block)
        # raises in case of 'security' violation

      #block = eval(block, @context.send(:binding))
        # doesn't work with ruby 1.9.2-p136
      block = eval(block, @context.instance_eval { binding })
        # works OK with ruby 1.8.7-249 and 1.9.2-p136

      r = if block.arity == 1

        block.call(workitem)
      else

        block.call(
          workitem, Ruote::Exp::FlowExpression.fetch(@context, workitem.h.fei))
      end

      if r != nil && r != workitem
        workitem.result = (Rufus::Json.dup(r) rescue nil)
      end

      reply_to_engine(workitem)
    end

    def cancel (fei, flavour)

      # do nothing
    end
  end
end

