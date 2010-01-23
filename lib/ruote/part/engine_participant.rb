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
# Made in Singapore.
#++

require 'ruote/subprocess'
require 'ruote/part/local_participant'


module Ruote

  #
  # Letting [segment of] processes run in another engine
  #
  class EngineParticipant

    include LocalParticipant

    def initialize (opts=nil)

      if pa = opts['storage_path']
        require pa
      end

      kl = opts['storage_class']

      raise(ArgumentError.new("missing 'storage_class' parameter")) unless kl

      @storage = Ruote.constantize(kl).new(opts['storage_args'])
    end

    def consume (workitem)

      wi = workitem.to_h
      fexp = Ruote::Exp::FlowExpression.fetch(@context, wi['fei'])
      params = wi['fields'].delete('params')

      @storage.put_msg(
        'launch',
        'wfid' => wi['fei']['wfid'],
        'sub_wfid' => fexp.get_next_sub_wfid,
        'parent_id' => wi['fei'],
        'tree' => determine_tree(fexp, params),
        'workitem' => wi,
        'variables' => fexp.compile_variables)
    end

    def cancel (fei, flavour)

      exps = @storage.get_many('expressions', /^0![^!]+!#{fei.wfid}$/)

      return true if exps.size < 1
        # participant expression will reply to its parent

      @storage.put_msg(
        'cancel',
        'fei' => exps.first['fei'],
        'flavour' => flavour)

      false
        # participant expression will NOT reply to its parent
    end

    def reply (fei, workitem)

      @storage.put_msg(
        'reply',
        'fei' => fei,
        'workitem' => workitem)
    end

    protected

    def determine_tree (fexp, params)

      pdef = params['def'] || params['pdef'] || params['tree']

      tree = Ruote.lookup_subprocess(fexp, pdef)

      raise(
        "couldn't find process definition behind '#{pdef}'"
      ) unless tree

      tree.last
    end
  end
end

