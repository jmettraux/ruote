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

  class HashStorage

    def initialize (options={})

      @options = options

      purge!
    end

    def put (doc)
      (@hash[doc['type']] ||= {})[doc['_id']] = doc
    end

    def get (type, key)
      @hash[type][key]
    end

    def delete (doc)
      @hash[doc['type']].delete(doc['_id'])
    end

    def purge!

      @hash = %w[
        tasks
        expressions
        errors
        ats
        crons
      ].inject({}) { |h, k|
        h[k] = {}
        h
      }
    end

    #--
    # CONFIGURATION
    #++

    def get_configuration

      @options
    end

    #--
    # SCHEDULES
    #++

    def get_at_schedules (time)

      p @hash

      @hash['ats']
    end

    def get_cron_schedules (time)

      @hash['crons']
    end

    #--
    # TASKS
    #++

    def get_tasks

      @hash['tasks'].values.sort { |t0, t1| t0['_id'] <=> t1['_id'] }
    end

    def put_task (action, args)

      args['type'] = 'tasks'
      args['action'] = action
      args['_id'] = Time.now.to_f.to_s

      put(args)
    end

    # Returns true if the task deletion succeeded (which means the worker
    # is free to process the task).
    #
    def delete_task (task)

      @hash['tasks'].shift

      true
    end

    #--
    # WFIDS
    #++

    def get_wfid_raw

      l = @hash['last'] || 0.0
      t = Time.now.to_f
      t = l + 0.001 if t <= l

      Time.at(t)
    end

    #--
    # EXPRESSIONS
    #++

    def get_expression (fei)

      @hash['expressions'][fei] || Ruote::MissingExpression.new
    end

    def get_expressions (wfid=nil)

      return @hash['expressions'].values unless wfid

      @hash['expressions'].inject([]) do |a, (fei, fexp)|

        a << fexp if fei.parent_wfid == wfid
        a
      end
    end

    #--
    # ERRORS
    #++

    def get_errors (wfid)

      @hash['expressions'].inject([]) do |a, (fei, err)|

        a << err if fei.parent_wfid == wfid
        a
      end
    end
  end
end

