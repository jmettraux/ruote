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
  # The class where despatchement of workitems towards [real] participant
  # is done.
  #
  # Can be extended/replaced for better handling of Thread (why not something
  # like a thread pool or no threads at all).
  #
  class DispatchPool

    def initialize(context)

      @context = context
    end

    def handle(msg)

      return unless msg['action'].match(/^dispatch/)

      send(msg['action'], msg)
    end

    protected

    # Dispatching the msg.
    #
    def dispatch(msg)

      participant = @context.plist.lookup(
        msg['participant'] || msg['participant_name'], msg['workitem'])

      if
        @context['participant_threads_enabled'] == false ||
        do_not_thread?(participant, msg)
      then
        do_dispatch(participant, msg)
      else
        do_threaded_dispatch(participant, msg)
      end
    end

    # The actual dispatching (call to Participant#consume or #on_workitem).
    #
    # No error rescuing so it might be interesting for some extension
    # classes (like in ruote-swf).
    #
    def do_raw_dispatch(participant, msg)

      workitem = Ruote::Workitem.new(msg['workitem'])

      workitem.fields['dispatched_at'] = Ruote.now_to_utc_s

      Ruote.participant_send(
        participant, [ :on_workitem, :consume ], 'workitem' => workitem)

      @context.storage.put_msg(
        'dispatched',
        'fei' => msg['fei'],
        'participant_name' => workitem.participant_name,
        'workitem' => msg['workitem'])
          # once the consume is done, asynchronously flag the
          # participant expression as 'dispatched'
    end

    # The raw dispatch work, wrapped in error handling.
    #
    def do_dispatch(participant, msg)

      do_raw_dispatch(participant, msg)

    rescue => err
      @context.error_handler.msg_handle(msg, err)
    end

    # Wraps the call to do_dispatch in a thread.
    #
    def do_threaded_dispatch(participant, msg)

      msg = Rufus::Json.dup(msg)
        #
        # the thread gets its own copy of the message
        # (especially important if the main thread does something with
        # the message 'during' the dispatch)

      # Maybe at some point a limit on the number of dispatch threads
      # would be OK.
      # Or maybe it's the job of an extension / subclass

      Thread.new { do_dispatch(participant, msg) }
    end

    # Returns true if the participant doesn't want the #consume to happen
    # in a new Thread.
    #
    def do_not_thread?(participant, msg)

      # :default => false makes participant_send return false if no method
      # were found (else it would raise a NoMethodError)

      Ruote.participant_send(
        participant,
        [ :do_not_thread, :do_not_thread?, :dont_thread, :dont_thread? ],
        'workitem' => Ruote::Workitem.new(msg['workitem']), :default => false)
    end

    # Instantiates the participant and calls its cancel method.
    #
    def dispatch_cancel(msg)

      flavour = msg['flavour']

      participant = @context.plist.instantiate(msg['participant'])

      result = begin

        Ruote.participant_send(
          participant,
          [ :on_cancel, :cancel ],
          'fei' => Ruote::FlowExpressionId.new(msg['fei']),
          'flavour' => flavour)

      rescue => e
        raise(e) if flavour != 'kill'
      end

      @context.storage.put_msg(
        'reply',
        'fei' => msg['fei'],
        'workitem' => msg['workitem']
      ) if result != false
    end

    # Instantiates the participant and calls its on_pause (or on_resume) method.
    #
    def dispatch_pause(msg)

      action = (msg['action'] == 'dispatch_resume' ? :on_resume : :on_pause)

      participant = @context.plist.instantiate(
        msg['participant'], :if_respond_to? => action)

      return unless participant

      Ruote.participant_send(
        participant,
        action,
        'fei' => Ruote::FlowExpressionId.new(msg['fei']), :default => false)
    end

    # Route to dispatch_pause which handles both pause and resume.
    #
    alias dispatch_resume dispatch_pause
  end

  # Given a participant, a method name or an array of method names and
  # a hash of arguments, will do its best to set the instance variables
  # corresponding to the arguments (if possible) and to call the
  # method with the right number of arguments...
  #
  # Made it a Ruote module method so that RevParticipant might use it
  # independently.
  #
  # If the arguments hash contains a value keyed :default, that value is
  # returned when none of the methods is responded to by the participant.
  # Else if :default is not set or is set to nil, a NoMethodError.
  #
  def self.participant_send(participant, methods, arguments)

    default = arguments.delete(:default)

    # set instance variables if possible

    arguments.each do |key, value|
      setter = "#{key}="
      participant.send(setter, value) if participant.respond_to?(setter)
    end

    # call the method, with the right arity

    Array(methods).each do |method|

      next unless participant.respond_to?(method)

      return participant.send(method) if participant.method(method).arity == 0

      args = arguments.keys.sort.collect { |k| arguments[k] }
        # luckily, our arg keys are in the alphabetical order (fei, flavour)

      return participant.send(method, *args)
    end

    return default unless default == nil

    raise NoMethodError.new(
      "undefined method `#{methods.first}' for #{participant.class}")
  end
end

