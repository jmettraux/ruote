#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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


require 'openwfe/workitem'
require 'openwfe/service'
require 'openwfe/util/observable'
require 'openwfe/participants/participants'


module OpenWFE

  #
  # A very simple directory of participants
  #
  class ParticipantMap < Service

    include OwfeServiceLocator
    include OwfeObservable

    attr_accessor :participants

    def initialize (service_name, application_context)

      super

      @participants = []
      @observers = {}
    end

    #
    # Returns how many participants are currently registered here.
    #
    def size

      @participants.size
    end

    #
    # Adds a participant to this map.
    # This method is called by the engine's own register_participant()
    # method.
    #
    # The participant instance is returned by this method call.
    #
    # The know params are :participant (a participant instance or
    # class) and :position (which can be null or :first).
    #
    # By default (if :position is not set to :first), the participant
    # will appear at the bottom of the participant list.
    #
    def register_participant (regex, params, &block)

      participant = params[:participant]
      position = params[:position]

      if not participant

        raise "please provide a participant instance or a block" unless block

        participant = BlockParticipant.new(block)
      end

      ldebug { "register_participant() participant.class #{participant.class}" }

      participant = instantiate_participant(regex, participant, params) \
        if participant.is_a?(Class)

      participant.application_context = @application_context \
        if participant.respond_to?(:application_context=)
          #
          # note that since 0.9.21 the application_context is passed in
          # the participant options as well.

      original_string = regex.to_s

      unless regex.is_a?(Regexp)

        regex = regex.to_s
        regex = '^' + regex unless regex[0, 1] == '^'
        regex = regex  + '$' unless regex[-1, 1] == '$'

        ldebug { "register_participant() '#{regex}'" }

        regex = Regexp.new(regex)
      end

      class << regex
        attr_reader :original_string
      end
      regex.instance_variable_set('@original_string', original_string)

      # now add the participant to the list

      entry = [ regex, participant ]

      index = (position == :first) ? 0 : -1

      @participants.insert(index, entry)

      participant
    end

    #
    # Looks up a participant given a participant_name.
    # Will return the first participant whose name matches.
    #
    def lookup_participant (participant_name)

      participant_name = participant_name.to_s

      @participants.each do |tuple|
        return tuple[1] if tuple[0].match(participant_name)
      end

      nil
    end

    #
    # Deletes the first participant matching the given name.
    #
    # If 'participant_name' is an integer, will remove the participant
    # at that position in the participant list.
    #
    def unregister_participant (participant_name)

      return (@participants.delete_at(participant_name) != nil) \
        if participant_name.is_a?(Integer)

      participant_name = participant_name.to_s

      par = @participants.find do |tuple|
        tuple[0].original_string == participant_name
      end
      @participants.delete(par) if par

      (par != nil)
    end

    #
    # Dispatches to the given participant (participant name (string) or
    # The workitem will be fed to the consume() method of that participant.
    # If it's a cancelitem and the participant has a cancel() method,
    # it will get called instead.
    #
    def dispatch (participant, participant_name, workitem)

      participant ||= lookup_participant(participant_name)
        # participant may be null (AliasParticipant)

      raise "pmap : no participant named '#{participant_name}'" \
        unless participant

      workitem.participant_name = participant_name

      if participant.respond_to?(:do_not_thread) and participant.do_not_thread
        do_dispatch(participant, workitem)
      else
        Thread.new { do_dispatch(participant, workitem) }
      end
    end

    #
    # When the engine is stopped, the participant map will run over
    # all the registered participants and call #stop on them, if they
    # implement a #stop method. Useful if your participants need to
    # clean up after themselves when the engine goes down.
    #
    def stop

      @participants.each do |participant|
        if participant[1].respond_to?(:stop)
          participant[1].stop
          linfo { "stop() stopped participant '#{participant[1].class}'" }
        end
      end
    end

    #
    # The method onotify (from Observable) is made public so that
    # ParticipantExpression instances may notify the pmap of applies
    # and replies.
    #
    public :onotify

    protected

    #
    # The participant to register has been passed as a class... Have to
    # instantiate it...
    #
    def instantiate_participant (regex, klass, options)

      options[:regex] = regex
      options[:application_context] = @application_context

      [
        [ regex, @application_context ], [ options ], []
      ].each do |args|
        begin
          return klass.new(*args)
        rescue Exception => e
        end
      end
    end

    #
    # The actual dispatch work is here, along with error catching
    #
    def do_dispatch (participant, workitem)

      return do_cancel(participant, workitem) if workitem.is_a?(CancelItem)

      onotify(:dispatch, :before_consume, workitem)

      workitem.dispatch_time = Time.now

      participant.consume(workitem)

      onotify(:dispatch, :after_consume, workitem)

    rescue Exception => e

      get_expression_pool.handle_error(e, workitem.fei, :apply, workitem)
    end

    #
    # Will call the cancel method of the participant if it has
    # one, or will simply discard the cancel item else.
    #
    def do_cancel (participant, cancel_item)

      participant.cancel(cancel_item) if participant.respond_to?(:cancel)

      onotify(:dispatch, :cancel, cancel_item)
        #
        # maybe it'd be better to specifically log that
        # a participant has no cancel() method, but it's OK
        # like that for now.
    end
  end

end

