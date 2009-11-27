#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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
  # Base methods for storage implementations.
  #
  module StorageBase

    def put_task (action, options)

      # merge! is way faster than merge (no object creation probably)

      put(options.merge!(
        'type' => 'tasks',
        '_id' => "#{$$}-#{Thread.current.object_id}-#{Time.now.to_f.to_s}",
        'action' => action))
    end

    def find_root_expression (wfid)

      get_many('expressions', /#{wfid}$/).sort { |a, b|
        a['fei']['expid'] <=> b['fei']['expid']
      }.select { |e|
        e['parent_id'].nil?
      }.first
    end

    def put_at_schedule (owner_fei, at, task)

      put_schedule('ats', owner_fei, at, task)
    end

    def put_cron_schedule (owner_fei, cron, task)

      put_schedule('crons', owner_fei, cron, task)
    end

    protected

    def put_schedule (type, owner_fei, t, task)

      if type == 'ats'

        at = t.strftime('%Y%m%d%H%M%S')
        i = "#{Ruote::FlowExpressionId.to_storage_id(owner_fei)}-#{at}"

      else

        raise "implement me !"
      end

      put(
        'type' => type,
        'owner' => owner_fei,
        '_id' => i,
        'task' => task)

      i
    end
  end
end

