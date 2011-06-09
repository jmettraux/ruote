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

      @subscribers = []
        # must be ready before the storage is created
        # services like Logger to subscribe to the worker

      @storage = storage
      @context = Ruote::Context.new(storage, self)

      @last_time = Time.at(0.0).utc # 1970...

      @running = true
      @run_thread = nil

      @msgs = []
      @sleep_time = 0.000
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

      Thread.abort_on_exception = true
        # TODO : remove me at some point

      @running = true

      @run_thread = Thread.new { run }
    end

    # Joins the run thread of this worker (if there is no such thread, this
    # method will return immediately, without any effect).
    #
    def join

      @run_thread.join if @run_thread
    end

    # Loggers and trackers call this method when subscribing for events /
    # actions in this worker.
    #
    def subscribe(actions, subscriber)

      @subscribers << [ actions, subscriber ]
    end

    # Shuts down this worker (makes sure it won't fetch further messages
    # and schedules).
    #
    def shutdown(join=true)

      @running = false

      if join
        begin
          @run_thread.join
        rescue Exception => e
        end
      else
        sleep(3)
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

      if delta >= 0.8
        #
        # at most once per second, deal with 'ats' and 'crons'

        @last_time = now

        @storage.get_schedules(delta, now).each { |sche| trigger(sche) }
      end

      # msgs

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

        #print r == false ? '*' : '.'

        break if Time.now.utc - @last_time >= 0.8
      end

      #p processed

      if processed == 0
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

        #else
          # msg got deleted, might still be interesting for a subscriber
        end

        notify(msg)

      rescue => exception

        @context.error_handler.msg_handle(msg, exception)
      end

      true
    end

    # Given a successfully executed msg, now notifies all the subscribers
    # interested in the kind of action the msg ordered.
    #
    def notify(msg)

      @subscribers.each do |actions, subscriber|

        if actions == :all || actions.include?(msg['action'])
          subscriber.notify(msg)
        end
      end
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

      wi['wf_name'] ||= (
        tree[1]['name'] || tree[1].keys.find { |k| tree[1][k] == nil })

      wi['wf_revision'] ||= (
        tree[1]['revision'] || tree[1]['rev'])

      exp_hash = {
        'fei' => msg['fei'] || {
          'engine_id' => @context.engine_id,
          'wfid' => msg['wfid'],
          'subid' => Ruote.generate_subid(msg.inspect),
          'expid' => '0' },
        'parent_id' => msg['parent_id'],
        'original_tree' => tree,
        'variables' => variables,
        'applied_workitem' => wi,
        'forgotten' => msg['forgotten']
      }

      if not exp_class

        exp_class = Ruote::Exp::RefExpression

      elsif is_launch?(msg, exp_class)

        def_name, tree = Ruote::Exp::DefineExpression.reorganize(tree)
        variables[def_name] = [ '0', tree ] if def_name
        exp_class = Ruote::Exp::SequenceExpression
      end

      exp = exp_class.new(@context, exp_hash.merge!('original_tree' => tree))

      exp.initial_persist
      exp.do_apply(msg)
    end

    # Returns true if the msg is a "launch" (ie not a simply "apply").
    #
    def is_launch?(msg, exp_class)

      return false if exp_class != Ruote::Exp::DefineExpression
      return true if msg['action'] == 'launch'
      (msg['trigger'] == 'on_re_apply')
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
  end
end

