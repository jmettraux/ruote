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

require 'ruote/fei'


module Ruote

  #
  # Workers fetch 'msgs' and 'schedules' from the storage and process them.
  #
  # Read more at http://ruote.rubyforge.org/configuration.html
  #
  class Worker

    EXP_ACTIONS = %w[ reply cancel fail receive dispatched ]
      # 'apply' is comprised in 'launch'
      # 'receive' is a ParticipantExpression alias for 'reply'

    PROC_ACTIONS = %w[ cancel_process kill_process ]

    attr_reader :storage
    attr_reader :context

    attr_reader :run_thread
    attr_reader :running

    def initialize (storage)

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

      while(@running) do
        step
      end
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

    def subscribe (actions, subscriber)

      @subscribers << [ actions, subscriber ]
    end

    def shutdown

      @running = false

      return unless @run_thread

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

    def step

      now = Time.now.utc
      delta = now - @last_time

      if delta >= 0.8
        #
        # at most once per second, deal with 'ats' and 'crons'

        @last_time = now

        @storage.get_schedules(delta, now).each do |sche|
          trigger(sche)
        end
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

    def trigger (schedule)

      msg = Ruote.fulldup(schedule['msg'])

      return false unless @storage.reserve(schedule)

      @storage.put_msg(msg.delete('action'), msg)

      true
    end

    def process (msg)

      return false if cannot_handle(msg)

      return false unless @storage.reserve(msg)

      begin

        action = msg['action']

        if msg['tree']
          #
          # warning here, it could be a reply, with a 'tree' key...

          launch(msg)

        elsif EXP_ACTIONS.include?(action)

          Ruote::Exp::FlowExpression.do_action(@context, msg)

        elsif action.match(/^dispatch/)

          @context.dispatch_pool.handle(msg)

        elsif PROC_ACTIONS.include?(action)

          self.send(action, msg)

        #else
          # msg got deleted, might still be interesting for a subscriber
        end

        notify(msg)

      rescue Exception => exception

        @context.error_handler.msg_handle(msg, exception)
      end

      true
    end

    def notify (msg)

      @subscribers.each do |actions, subscriber|

        if actions == :all || actions.include?(msg['action'])
          subscriber.notify(msg)
        end
      end
    end

    # Should always return false. Except when the message is a 'dispatch'
    # and it's for a participant only available to an 'engine_worker'
    # (block participants, stateful participants)
    #
    def cannot_handle (msg)

      return false if msg['action'] != 'dispatch'

      @context.engine.nil? && msg['for_engine_worker?']
    end

    # Works for both the 'launch' and the 'apply' msgs.
    #
    def launch (msg)

      tree = msg['tree']
      variables = msg['variables']

      exp_class = @context.expmap.expression_class(tree.first)

      # msg['wfid'] only : it's a launch
      # msg['fei'] : it's a sub launch (a supplant ?)

      exp_hash = {
        'fei' => msg['fei'] || {
          'engine_id' => @context.engine_id,
          'wfid' => msg['wfid'],
          'sub_wfid' => msg['sub_wfid'],
          'expid' => '0' },
        'parent_id' => msg['parent_id'],
        'original_tree' => tree,
        'variables' => variables,
        'applied_workitem' => msg['workitem'],
        'forgotten' => msg['forgotten']
      }

      if not exp_class

        exp_class, tree = lookup_subprocess_or_participant(exp_hash)

      elsif msg['action'] == 'launch' && exp_class == Ruote::Exp::DefineExpression
        def_name, tree = Ruote::Exp::DefineExpression.reorganize(tree)
        variables[def_name] = [ '0', tree ] if def_name
        exp_class = Ruote::Exp::SequenceExpression
      end

      if exp_class == Ruote::Exp::SubprocessExpression && tree[1]['engine']
        #
        # the subprocess has to be transformed into an EngineParticipant...

        exp_class = Ruote::Exp::ParticipantExpression

        atts = tree[1]

        if ref = atts.find { |k, v| v.nil? }
          ref = ref.first
          atts.delete(ref)
        end

        atts['pdef'] = atts['ref'] || ref
        atts['ref'] = atts.delete('engine')
      end

      raise_unknown_expression_error(exp_hash) unless exp_class

      exp = exp_class.new(@context, exp_hash.merge!('original_tree' => tree))

      exp.initial_persist
      exp.do_apply
    end

    def raise_unknown_expression_error (exp_hash)

      exp_hash['state'] = 'failed'
      #exp_hash['has_error'] = true

      Ruote::Exp::RawExpression.new(@context, exp_hash).persist_or_raise
        # undigested expression is stored

      raise "unknown expression '#{exp_hash['original_tree'].first}'"
    end

    def lookup_subprocess_or_participant (exp_hash)

      tree = exp_hash['original_tree']

      key, value = Ruote::Exp::FlowExpression.new(
        @context, exp_hash.merge('name' => 'temporary')
      ).iterative_var_lookup(tree[0])

      sub = value
      part = @context.plist.lookup_info(key)

      sub = key if (not sub) && (not part) && Ruote.is_uri?(key)
        # for when a variable points to the URI of a[n external] subprocess

      if sub or part

        tree[1]['ref'] = key
        tree[1]['original_ref'] = tree[0] if key != tree[0]

        if sub
          [ Ruote::Exp::SubprocessExpression, [ 'subprocess', *tree[1..2] ] ]
        else
          [ Ruote::Exp::ParticipantExpression, [ 'participant', *tree[1..2] ] ]
        end
      else

        [ nil, tree ]
      end
    end

    def cancel_process (msg)

      root = @storage.find_root_expression(msg['wfid'])

      return unless root

      flavour = (msg['action'] == 'kill_process') ? 'kill' : nil

      @storage.put_msg(
        'cancel',
        'fei' => root['fei'],
        'wfid' => msg['wfid'], # indicates this was triggered by cancel_process
        'flavour' => flavour)
    end

    alias :kill_process :cancel_process
  end
end

