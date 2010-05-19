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
  # Logs the ruote engine history to the storage underlying the worker.
  #
  # Warning : don't use this history implementation when the storage is
  # HashStorage. It will fill up your memory... Keeping history for a
  # transient ruote is a bit overkill (IMHO).
  #
  class StorageHistory

    DATE_REGEX = /!(\d{4}-\d{2}-\d{2})!/

    def initialize (context, options={})

      @context = context
      @options = options

      if @context.worker

        # only care about logging if there is a worker present

        @context.storage.add_type('history')
        @context.worker.subscribe(:all, self)
      end
    end

    def by_process (wfid)

      @context.storage.get_many('history', /!#{wfid}$/)
    end
    alias :by_wfid :by_process

    # Returns an array [ most recent date, oldest date ] (Time instances).
    #
    def range

      ids = @context.storage.ids('history')

      #p ids.sort == ids

      fm = DATE_REGEX.match(ids.first)[1]
      lm = DATE_REGEX.match(ids.last)[1]

      first = Time.parse("#{fm} 00:00:00 UTC")
      last = Time.parse("#{lm} 00:00:00 UTC") + 24 * 3600

      [ first, last ]
    end

    def by_date (date)

      date = Time.parse(date.to_s).strftime('%Y-%m-%d')

      @context.storage.get_many('history', /!#{date}!/)
    end

    #def history_to_tree (wfid)
    #  # (NOTE why not ?)
    #end

    # The history system doesn't implement purge! so that when purge! is called
    # on the engine, the history is not cleared.
    #
    # Call this *dangerous* clear! method to clean out any history file.
    #
    def clear!

      @context.storage.purge_type!('history')
    end

    # This is the method called by the workqueue. Incoming engine events
    # are 'processed' here.
    #
    def notify (msg)

      msg = msg.dup
        # a shallow copy is sufficient

      si = if fei = msg['fei']
        Ruote::FlowExpressionId.to_storage_id(fei)
      else
        msg['wfid'] || 'no_wfid'
      end

      _id = msg['_id']
      msg['original_id'] = _id
      msg['_id'] = "#{_id}!#{si}"

      msg['type'] = 'history'
      msg['original_put_at'] = msg['put_at']

      msg.delete('_rev')

      @context.storage.put(msg)
    end
  end
end

