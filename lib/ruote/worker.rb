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

require 'ruote/fei'


module Ruote

  #
  # Workers fetch 'msgs' and 'schedules' from the storage and process them.
  #
  # Read more at http://ruote.rubyforge.org/configuration.html
  #
  class Worker

    EXP_ACTIONS = %w[ reply cancel fail receive dispatched pause resume ]
      # 'apply' is comprised in 'launch'
      # 'receive' is a ParticipantExpression alias for 'reply'

    PROC_ACTIONS = %w[ cancel kill pause resume ].collect { |a| a + '_process' }
    DISP_ACTIONS = %w[ dispatch dispatch_cancel dispatch_pause dispatch_resume ]

    attr_reader :storage
    attr_reader :context

    attr_reader :run_thread
    attr_reader :running

    # Given a storage, creates a new instance of a Worker.
    #
    def initialize(storage)

      if storage.respond_to?(:storage)
        @storage = storage.storage
        @context = storage.context
      else
        @storage = storage
        @context = Ruote::Context.new(storage)
      end
      @context.add_service('worker', self)

      @last_time = Time.at(0.0).utc # 1970...

      @running = true
      @run_thread = nil

      @msgs = []

      @sleep_time = @context['restless_worker'] ? nil : 0.000

      @info = Info.new(self)
    end

    # Runs the worker in the current thread. See #run_in_thread for running
    # in a dedicated thread.
    #
    def run

      step while @running
    end

    # Triggers the run method of the worker in a dedicated thread.
    #
    def run_in_thread

      #Thread.abort_on_exception = true

      @running = true

      @run_thread = Thread.new { run }
    end

    # Joins the run thread of this worker (if there is no such thread, this
    # method will return immediately, without any effect).
    #
    def join

      @run_thread.join if @run_thread
    end

    # Shuts down this worker (makes sure it won't fetch further messages
    # and schedules).
    #
    def shutdown

      @running = false

      begin
        @run_thread.join
      rescue Exception => e
      end
    end

    # Returns true if the engine system is inactive, ie if all the process
    # instances are terminated or are stuck in an error.
    #
    # NOTE : for now, if a branch of a process is in error while another is
    # still running, this method will consider the process instance inactive
    # (and it will return true if all the processes are considered inactive).
    #
    def inactive?

      # the cheaper tests first

      return false if @msgs.size > 0
      return false unless @context.storage.empty?('schedules')
      return false unless @context.storage.empty?('msgs')

      wfids = @context.storage.get_many('expressions').collect { |exp|
        exp['fei']['wfid']
      }

      error_wfids = @context.storage.get_many('errors').collect { |err|
        err['fei']['wfid']
      }

      (wfids - error_wfids == [])
    end

    protected

    # One worker step, fetches schedules and triggers those whose time has
    # came, then fetches msgs and processes them.
    #
    def step

      now = Time.now.utc
      delta = now - @last_time

      #
      # trigger schedules whose time has come

      if delta >= 0.8
        #
        # at most once per second, deal with 'ats' and 'crons'

        @last_time = now

        @storage.get_schedules(delta, now).each { |sche| trigger(sche) }
      end

      #
      # process msgs (atomic workflow operations)

      @msgs = @storage.get_msgs if @msgs.empty?

      processed = 0
      collisions = 0

      while msg = @msgs.shift

        r = process(msg)

        if r != false
          processed += 1
        else
          collisions += 1
        end

        if collisions > 2
          @msgs = @msgs[(@msgs.size / 2)..-1] || []
        end

        #@msgs.concat(@storage.get_local_msgs)

        break if Time.now.utc - @last_time >= 0.8
      end

      #
      # batch over

      take_a_rest(processed)
    end

    # In order not to hammer the storage for msgs too much, take a rest.
    #
    # If the number of processed messages is more than zero, there are probably
    # more msgs coming, no time for a rest...
    #
    # If @sleep_time is nil (restless_worker option set to true), the worker
    # will never rest.
    #
    def take_a_rest(msgs_processed)

      return if @sleep_time == nil

      if msgs_processed == 0

        @sleep_time += 0.001
        @sleep_time = 0.499 if @sleep_time > 0.499

        sleep(@sleep_time)

      else

        @sleep_time = 0.000
      end
    end

    # Given a schedule, attempts to trigger it.
    #
    # It first tries to
    # reserve the schedule. If the reservation fails (another worker
    # was successful probably), false is returned. The schedule is
    # triggered if the reservation was successful, true is returned.
    #
    def trigger(schedule)

      msg = Ruote.fulldup(schedule['msg'])

      return false unless @storage.reserve(schedule)

      @storage.put_msg(msg.delete('action'), msg)

      true
    end

    # Processes one msg.
    #
    # Will return false immediately if the msg reservation failed (another
    # worker grabbed the message.
    #
    # Else will execute the action ordered in the msg, and return true.
    #
    # Exceptions in execution are intercepted here and passed to the
    # engine's (context's) error_handler.
    #
    def process(msg)

      return false unless @storage.reserve(msg)

      begin

        action = msg['action']

        if msg['tree']
          #
          # warning here, it could be a reply, with a 'tree' key...

          launch(msg)

        elsif EXP_ACTIONS.include?(action)

          Ruote::Exp::FlowExpression.do_action(@context, msg)

        elsif DISP_ACTIONS.include?(action)

          @context.dispatch_pool.handle(msg)

        elsif PROC_ACTIONS.include?(action)

          self.send(action, msg)

        elsif action == 'put_doc'

          put_doc(msg)

        #else
          # no special processing required for message, let it pass
          # to the subscribers (the notify two lines after)
        end

        @context.notify(msg)
          # notify subscribers of successfully processed msgs

      rescue => exception

        @context.error_handler.msg_handle(msg, exception)
      end

      @context.storage.done(self, msg) if @context.storage.respond_to?(:done)

      @info << msg
        # for the stats

      true
    end

    # Works for both the 'launch' and the 'apply' msgs.
    #
    # Creates a new expression, gives and applies it with the
    # workitem contained in the msg.
    #
    def launch(msg)

      tree = msg['tree']
      variables = msg['variables']
      wi = msg['workitem']

      exp_class = @context.expmap.expression_class(tree.first)

      # msg['wfid'] only : it's a launch
      # msg['fei'] : it's a sub launch (a supplant ?)

      if is_launch?(msg, exp_class)

        wi['wf_name'] ||= (
          tree[1]['name'] || tree[1].keys.find { |k| tree[1][k] == nil })
        wi['wf_revision'] ||= (
          tree[1]['revision'] || tree[1]['rev'])
      end

      exp_hash = {
        'fei' => msg['fei'] || {
          'engine_id' => @context.engine_id,
          'wfid' => msg['wfid'],
          'subid' => Ruote.generate_subid(msg.inspect),
          'expid' => msg['expid'] || '0' },
        'parent_id' => msg['parent_id'],
        'variables' => variables,
        'applied_workitem' => wi,
        'forgotten' => msg['forgotten'],
        'lost' => msg['lost'],
        'flanking' => msg['flanking'],
        'stash' => msg['stash'] }

      if not exp_class

        exp_class = Ruote::Exp::RefExpression

      elsif is_launch?(msg, exp_class)

        def_name, tree = Ruote::Exp::DefineExpression.reorganize(tree)
        variables[def_name] = [ '0', tree ] if def_name
        exp_class = Ruote::Exp::SequenceExpression
      end

      exp_hash = exp_hash.inject({}) { |h, (k, v)| h[k] = v unless v.nil?; h }
      exp_hash['original_tree'] = tree
        #
        # dropping nils
        # and registering potentially reorganized tree

      exp = exp_class.new(@context, exp_hash)

      exp.initial_persist
      exp.do_apply(msg)
    end

    # Returns true if the msg is a "launch" (ie not a simply "apply").
    #
    def is_launch?(msg, exp_class)

      if exp_class != Ruote::Exp::DefineExpression
        false
      elsif msg['action'] == 'launch'
        true
      else
        (msg['trigger'] == 'on_re_apply')
      end
    end

    # Handles a 'cancel_process' msg (translates it into a "cancel root
    # expression of that process" msg).
    #
    # Also works for 'kill_process' msgs.
    #
    def cancel_process(msg)

      root = @storage.find_root_expression(msg['wfid'])

      return unless root

      @storage.put_msg(
        'cancel',
        'fei' => root['fei'],
        'wfid' => msg['wfid'], # indicates this was triggered by cancel_process
        'flavour' => msg['action'] == 'kill_process' ? 'kill' : nil)
    end

    alias kill_process cancel_process

    # Handles 'pause_process' and 'resume_process'.
    #
    def pause_process(msg)

      root = @storage.find_root_expression(msg['wfid'])

      return unless root

      @storage.put_msg(
        msg['action'] == 'pause_process' ? 'pause' : 'resume',
        'fei' => root['fei'],
        'wfid' => msg['wfid']) # it was triggered by {pause|resume}_process
    end

    alias resume_process pause_process

    # Puts a document in the storage, must succeed (ie will happily steal
    # the current _rev to place its doc).
    #
    def put_doc(msg)

      doc = msg['doc']

      r = @storage.put(doc)

      return unless r.is_a?(Hash)

      doc['_rev'] = r['_rev']

      put_doc(msg)
    end

    #
    # Gathering stats about this worker.
    #
    # Those stats can then be obtained via Dashboard#worker_info
    # (Engine#worker_info).
    #
    class Info

      def initialize(worker)

        @worker = worker
        @ip = Ruote.local_ip
        @hostname = `hostname`.strip rescue nil
        @system = `uname -a`.strip rescue nil

        @since = Time.now
        @msgs = []
        @last_save = Time.now - 2 * 60
      end

      def <<(msg)

        pp msg if msg['put_at'].nil?

        @msgs << {
          'processed_at' => Ruote.now_to_utc_s,
          'wait_time' => Time.now - Time.parse(msg['put_at'])
          #'action' => msg['action']
        }

        save if Time.now > @last_save + 60
      end

      protected

      def save

        doc = @worker.storage.get('variables', 'workers') || {}

        doc['type'] = 'variables'
        doc['_id'] = 'workers'

        now = Time.now

        @msgs = @msgs.drop_while { |msg|
          Time.parse(msg['processed_at']) < now - 3600
        }
        mm = @msgs.drop_while { |msg|
          Time.parse(msg['processed_at']) < now - 60
        }

        hour_count = @msgs.size < 1 ? 1 : @msgs.size
        minute_count = mm.size < 1 ? 1 : mm.size

        (doc['workers'] ||= {})["#{@ip}/#{$$}"] = {

          'class' => @worker.class.to_s,
          'ip' => @ip,
          'hostname' => @hostname,
          'pid' => $$,
          'system' => @system,
          'put_at' => Ruote.now_to_utc_s,
          'uptime' => Time.now - @since,

          'processed_last_minute' =>
            minute_count,
          'wait_time_last_minute' =>
            mm.inject(0.0) { |s, m| s + m['wait_time'] } / minute_count.to_f,
          'processed_last_hour' =>
            hour_count,
          'wait_time_last_hour' =>
            @msgs.inject(0.0) { |s, m| s + m['wait_time'] } / hour_count.to_f
        }

        r = @worker.storage.put(doc)

        @last_save = Time.now

        save unless r.nil?
      end
    end
  end
end

