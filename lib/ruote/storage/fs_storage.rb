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

require 'rufus/cloche'


module Ruote

  class FsStorage

    def initialize (dir, options={})

      @cloche = Rufus::Cloche.new(:dir => dir)
      @options = options
    end

    def get_at_schedules (time)

      @cloche.get_many('ats')
    end

    def get_cron_schedules (time)

      @cloche.get_many('crons')
    end

    def get_tasks

      @cloche.get_many('tasks')
    end

    def get_expression (fei)

      @cloche.get('expressions', fei) || Ruote::MissingExpression.new
    end

    def get_configuration

      @options.merge(@cloche.get('configurations', 'ruote'))
    end

    # Returns true if the task deletion succeeded (which means the worker
    # is free to process the task).
    #
    def delete_task (task)

      @cloche.delete(task).nil?
    end

    def get_wfid_raw

      h =
        @cloche.get('wfid', 'last') ||
        { '_id' => 'last', 'type' => 'wfid', 'last' => 0.0 }

      l = h['last']

      t = Time.now.to_f
      t = l + 0.001 if t <= l

      h['last'] = t

      r = @cloche.put(h)

      return get_wfid_raw if r

      Time.at(t)
    end

    def put_task (action, args)

      args['type'] = 'task'
      args['action'] = 'action'
      args['_id'] = Time.now.to_f.to_s

      @cloche.put(args)
    end
  end
end

