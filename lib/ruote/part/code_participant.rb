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


module Ruote

  #
  # TODO
  #
  class CodeParticipant

    include LocalParticipant

    attr_accessor :context

    def initialize(opts)

      @opts = opts
    end

    def context=(con)

      @context = con

      @context.treechecker.code_check(@opts['code'])

      instance_eval(@opts['code'])

      #instance_eval do
      #  alias code_consume consume
      #  def consume(workitem)
      #    code_consume(workitem)
      #  rescue => e
      #    raise e
      #  end
      #  # what about doing that with other methods
      #end
    end

    protected

#    def get_block(*keys)
#
#      key = keys.find { |k| @opts[k] }
#
#      return nil unless key
#
#      block = @opts[key]
#
#      @context.treechecker.block_check(block)
#        # raises in case of 'security' violation
#
#      #eval(block, @context.send(:binding))
#        # doesn't work with ruby 1.9.2-p136
#      eval(block, @context.instance_eval { binding })
#        # works OK with ruby 1.8.7-249 and 1.9.2-p136
#    end
  end
end

