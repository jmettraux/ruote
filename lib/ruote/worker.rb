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

require 'ruote/fei'


module Ruote

  # A helper for the #worker method, it returns that dummy worker
  # when there is no reference to the calling worker in the current
  # thread's local variables.
  #
  DUMMY_WORKER = OpenStruct.new(
    :name => 'worker', :identity => 'unknown', :state => 'running')

  # Warning, this is not equivalent to doing @context.worker, this method
  # fetches the worker from the local thread variables.
  #
  def self.current_worker

    Thread.current['ruote_worker'] || DUMMY_WORKER
  end

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

    attr_reader :name

    attr_reader :storage
    attr_reader :context

    attr_reader :state
    attr_reader :run_thread

    # Given a storage, creates a new instance of a Worker.
    #
    def initialize(name, storage=nil)

      if storage.nil?
        storage = name
        name = nil
      end

      @name = name || 'worker'

      if storage.respond_to?(:storage)
        @storage = storage.storage
        @context = storage.context
      else
        @storage = storage
        @context = Ruote::Context.new(storage)
      end

      service_name = @name
      service_name << '_worker' unless service_name.match(/worker$/)

      @context.add_service(service_name, self)

      @last_time = Time.at(0.0).utc # 1970...

      @state = 'running'
      @run_thread = nil
      @state_mutex = Mutex.new

      @msgs = []

      @sleep_time = @context['restless_worker'] ? nil : 0.000

      @info = @context['worker_info_enabled'] == false ? nil : Info.new(self)
    end

    # Runs the worker in the current thread. See #run_in_thread for running
    # in a dedicated thread.
    #
    def run

      step while @state != 'stopped'
    end

    # Triggers the run method of the worker in a dedicated thread.
    #
    def run_in_thread

      #Thread.abort_on_exception = true

      @state = 'running'

      @run_thread = Thread.new { run }
      @run_thread['ruote_worker'] = self
    end

    # Joins the run thread of this worker (if there is no such thread, this
    # method will return immediately, without any effect).
    #
    def join

      @run_thread.join rescue nil
    end

    # Shuts down this worker (makes sure it won't fetch further messages
    # and schedules).
    #
    def shutdown

      @state_mutex.synchronize { @state = 'stopped' }

      join
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

    # If worker_state_enabled is set, check for a potential new state.
    #
    def determine_state

      @state_mutex.synchronize do

        @state = (
          @storage.get('variables', 'worker') || { 'state' => 'running' }
        )['state'] if @state != 'stopped' && @context['worker_state_enabled']
      end
    end

    # Gets schedules from the storage and if their time has come,
    # turns them into msg (for immediate execution).
    #
    def process_schedules

      now = Time.now.utc
      delta = now - @last_time

      return if delta < 0.8
        #
        # consider schedules at most twice per second (don't do that job
        # too often)

      @last_time = now

      @storage.get_schedules(delta, now).each { |s| turn_schedule_to_msg(s) }
    end

    # Gets msgs from the storage (if needed) and processes them one by one.
    #
    def process_msgs

      @msgs = @storage.get_msgs if @msgs.empty?

      collisions = 0

      while @msg = @msgs.shift

        r = process(@msg)

        if r != false
          @processed_msgs += 1
        else
          collisions += 1
        end

        if collisions > 2
          @msgs = @msgs[(@msgs.size / 2)..-1] || []
          collisions = 0
        end

        break if Time.now.utc - @last_time >= 0.8
      end
    end

    # Some storage implementations cache information before a step
    # begins, reducing the number of requests to the underlying
    # data system. This begin step notifies the storage that
    # a new step is on and it should refresh the cached information.
    #
    # The storage implementation, if it supports this feature, will cache
    # the information in the thread local info.
    #
    def begin_step

      Thread.current['ruote_worker'] = self

      @storage.begin_step if @storage.respond_to?(:begin_step)
    end

    # One worker step, fetches schedules and triggers those whose time has
    # came, then fetches msgs and processes them.
    #
    def step

      begin_step

      @msg = nil
      @processed_msgs = 0

      determine_state

      if @state == 'stopped'
        return
      elsif @state == 'running'
        process_schedules
        process_msgs
      end

      take_a_rest # 'running' or 'paused'

    rescue => err

      handle_step_error(err, @msg) # msg may be nil
    end

    # This default implementation dumps error information to $stderr as
    # soon as #step intercepts the error.
    #
    # Normally such information should only appear when developing a
    # storage, the information here is thus helpful for storage developers.
    # If such info is emitted in production or in application development,
    # you should pass the info to the storage developer/maintainer.
    #
    # Feel free to override this method if you need it to output to
    # a channel different than $stderr (or rebind $stderr).
    #
    # The second parameter is "msg", if the error occured while processing a
    # msg, then this message is passed to handle_step_error. msg will be
    # nil if the error occurred while doing get_msgs or get_schedules.
    #
    def handle_step_error(err, msg)

      $stderr.puts '#' * 80
      $stderr.puts
      $stderr.puts '** worker#step intercepted exception **'
      $stderr.puts
      $stderr.puts "Please report issue or fix your #{@storage.class} impl,"
      $stderr.puts
      $stderr.puts "or override Ruote::Worker#handle_step_error(e, msg) so that"
      $stderr.puts "the issue is dealt with appropriately. For example:"
      $stderr.puts
      $stderr.puts "    class Ruote::Worker"
      $stderr.puts "      def handle_step_error(e, msg)"
      $stderr.puts "        logger.error('ruote step error: ' + e.inspect)"
      $stderr.puts "        mailer.send_error('admin@acme.com', e)"
      $stderr.puts "      end"
      $stderr.puts "    end"
      $stderr.puts
      $stderr.puts '# ' * 40
      $stderr.puts
      $stderr.puts 'error class/message/backtrace:'
      $stderr.puts err.class.name
      $stderr.puts err.message.inspect
      $stderr.puts *err.backtrace
      $stderr.puts err.details if err.respond_to?(:details)
      $stderr.puts
      $stderr.puts 'msg:'
      if msg && msg.is_a?(Hash)
        $stderr.puts msg.select { |k, v|
          %w[ action wfid fei ].include?(k)
        }.inspect
      else
        $stderr.puts msg.inspect
      end
      $stderr.puts
      $stderr.puts '#' * 80

      $stderr.flush
    end

    # In order not to hammer the storage for msgs too much, take a rest.
    #
    # If the number of processed messages is more than zero, there are probably
    # more msgs coming, no time for a rest...
    #
    # If @sleep_time is nil (restless_worker option set to true), the worker
    # will never rest.
    #
    def take_a_rest

      return if @sleep_time == nil

      if @processed_msgs < 1

        @sleep_time += 0.001
        @sleep_time = 0.499 if @sleep_time > 0.499

        sleep(@sleep_time)

      else

        @sleep_time = 0.000
      end
    end

    # Given a schedule, attempts to trigger it.
    #
    # It first tries to reserve the schedule. If the reservation fails
    # (another worker was successful probably), false is returned.
    # The schedule is triggered if the reservation was successful, true
    # is returned.
    #
    def turn_schedule_to_msg(schedule)

      return false unless @storage.reserve(schedule)

      msg = Ruote.fulldup(schedule['msg'])

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

        @context.pre_notify(msg)

        case msg['action']

          when 'launch', 'apply', 'regenerate'

            launch(msg)

          when *EXP_ACTIONS

            Ruote::Exp::FlowExpression.do_action(@context, msg)

          when *DISP_ACTIONS

            @context.dispatch_pool.handle(msg)

          when *PROC_ACTIONS

            self.send(msg['action'], msg)

          when 'reput'

            reput(msg)

          when 'raise'

            @context.error_handler.msg_handle(msg['msg'], msg['error'])

          when 'respark'

            respark(msg)

          #else
            # no special processing required for message, let it pass
            # to the subscribers (the notify two lines after)
        end

        @context.notify(msg)
          # notify subscribers of successfully processed msgs

      rescue => err

        @context.error_handler.msg_handle(msg, err)
      end

      @context.storage.done(msg) if @context.storage.respond_to?(:done)

      @info << msg if @info
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

      # msg['wfid'] only:  it's a launch
      # msg['fei']:        it's a sub launch (a supplant ?)

      if is_launch?(msg, exp_class)

        name = tree[1]['name'] || tree[1].keys.find { |k| tree[1][k] == nil }
        revision = tree[1]['revision'] || tree[1]['rev']

        wi['wf_name'] ||= name
        wi['wf_revision'] ||= revision
        wi['wf_launched_at'] ||= Ruote.now_to_utc_s

        wi['sub_wf_name'] = name
        wi['sub_wf_revision'] = revision
        wi['sub_wf_launched_at'] = Ruote.now_to_utc_s
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
        'attached' => msg['attached'],
        'supplanted' => msg['supplanted'],

        'stash' => msg['stash'],
        'trigger' => msg['trigger'],
        'on_reply' => msg['on_reply']
      }

      if not exp_class

        exp_class = Ruote::Exp::RefExpression

      elsif is_launch?(msg, exp_class)

        def_name, tree = Ruote::Exp::DefineExpression.reorganize(tree)
        variables[def_name] = [ '0', tree ] if def_name
        exp_class = Ruote::Exp::SequenceExpression
      end

      exp_hash = exp_hash.reject { |k, v| v.nil? }
        # compact nils away

      exp_hash['original_tree'] = tree
        # keep track of original tree

      exp = exp_class.new(@context, exp_hash)

      exp.initial_persist
      exp.do(:apply, msg)
    end

    # Returns true if the msg is a "launch" (ie not a simply "apply").
    #
    def is_launch?(msg, exp_class)

      if exp_class != Ruote::Exp::DefineExpression
        false
      elsif %w[ launch regenerate ].include?(msg['action'])
        true
      else
        (msg['trigger'] == 'on_re_apply')
          # let re-apply "define" blocks, as in Ruote.define {}
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
        'flavour' => msg['flavour'])
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

    # Reputs a doc or a msg.
    #
    # Used by certain storage implementations to pass documents around workers
    # or to reschedule msgs (see ruote-swf).
    #
    def reput(msg)

      if doc = msg['doc']

        r = @storage.put(doc)

        return unless r.is_a?(Hash)

        doc['_rev'] = r['_rev']

        reput(msg)

      elsif msg = msg['msg']

        @storage.put_msg(msg['action'], msg)
      end
    end

    # This action resparks a stalled workflow instance. It's usually
    # triggered via Dashboard#respark
    #
    # It's been made into a msg (worker action) in order to facilitate
    # migration tooling (ruote-swf for example).
    #
    def respark(msg)

      wfid = msg['wfid']
      opts = msg['respark']

      ps = ProcessStatus.fetch(@context, [ wfid ], {}).first

      error_feis = ps.errors.collect(&:fei)
      errors_too = !! opts['errors_too']

      ps.leaves.each do |fexp|

        next if errors_too == false && error_feis.include?(fexp.fei)

        @context.storage.put_msg(
          'cancel', 'fei' => fexp.fei.h, 're_apply' => {})
      end
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
        @hostname = Socket.gethostname
        @system = `uname -a`.strip rescue nil

        @since = Time.now
        @msgs = []
        @last_save = Time.now - 2 * 60
      end

      def <<(msg)

        if msg['put_at'].nil?
          puts '-' * 80
          puts "msg missing 'put_at':"
          pp msg
          puts '-' * 80
        end

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

        key = [
          @worker.name, @ip.gsub(/\./, '_'), $$.to_s
        ].join('/')

        (doc['workers'] ||= {})[key] = {

          'class' => @worker.class.to_s,
          'name' => @name,
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

        save if r != nil
      end
    end
  end
end

