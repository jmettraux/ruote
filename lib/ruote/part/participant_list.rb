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


require 'ruote/part/block_participant'


module Ruote

  #
  # Tracking participants to [business] processes.
  #
  # The methods here are mostly called via the engine (registering /
  # unregistering participants) and via the dispatch_pool (when handing
  # workitems to participants).
  #
  class ParticipantList

    attr_reader :instantiated_participants

    def initialize (context)

      @context = context
      @instantiated_participants = {}
    end

    # Registers a participant. Called by Engine#register_participant.
    #
    def register (name, participant, options, block)

      options = options.inject({}) { |h, (k, v)|
        h[k.to_s] = v.is_a?(Symbol) ? v.to_s : v
        h
      }

      entry = if participant.is_a?(Class) || participant.is_a?(String)
        [ participant.to_s, options ]
      else
        "inpa_#{name.inspect}"
          # INstantiated PArticipant
      end

      key = (name.is_a?(Regexp) ? name : Regexp.new("^#{name}$")).source

      entry = [ key, entry ]

      list = get_list

      list['list'].delete_if { |e| e.first == key }

      position = options['position'] || 'last'
      case position
        when 'last' then list['list'] << entry
        when 'first' then list['list'].unshift(entry)
        when Fixnum then list['list'].insert(position, entry)
        else raise "cannot insert participant at position '#{position}'"
      end

      if r = @context.storage.put(list)
        #
        # if put returns something it means the put failed, have to redo the
        # work...
        #
        return register(name, participant, options, block, r)
      end

      if entry.last.is_a?(String)

        participant = BlockParticipant.new(block, options) if block

        participant.context = @context if participant.respond_to?(:context=)
        @instantiated_participants[entry.last] = participant
        #participant

      else

        if entry.last.first == 'Ruote::StorageParticipant'
          return Ruote::StorageParticipant.new(@context)
        end

        nil
      end
    end

    # Removes a participant, given via its name or directly from this
    # participant list.
    #
    # Called usually by Engine#unregister_participant.
    #
    def unregister (name_or_participant)

      code = nil
      entry = nil
      list = get_list

      if name_or_participant.is_a?(Symbol)
        name_or_participant = name_or_participant.to_s
      end

      if name_or_participant.is_a?(String)

        entry = list['list'].find { |re, pa| name_or_participant.match(re) }

        return nil unless entry

        code = entry.last if entry.last.is_a?(String)

      else # we've been given a participant instance

        code = @instantiated_participants.find { |k, v|
          v == name_or_participant
        }

        return nil unless code

        code = code.first

        entry = list['list'].find { |re, pa| pa == code }

      end

      list['list'].delete(entry)

      if r = @context.storage.put(list)
        #
        # put failed, have to redo it
        #
        return unregister(name_or_participant, r)
      end

      @instantiated_participants.delete(code) if code

      entry.first
    end

    # Given a participant name, returns
    #
    # Returns nil if there is no participant registered that covers the given
    # participant name.
    #
    def lookup_info (participant_name)

      re, pa = get_list['list'].find { |rr, pp| participant_name.match(rr) }

      case pa
        when nil then nil
        when String then @instantiated_participants[pa]
        else pa
      end
    end

    # Returns an instance of a participant
    #
    def instantiate (o, opts={})

      pi = (o.is_a?(String) || o.is_a?(Array) || o.respond_to?(:consume)) ?
        o :
        o['participant'] || o['participant_name']

      pi = lookup_info(pi) if pi.is_a?(String)

      return nil unless pi
        # not found

      irt = opts[:if_respond_to?]

      if pi.respond_to?(:consume)
        return nil if irt && ( ! pi.respond_to?(irt))
        return pi
      end

      class_name, options = pi

      if rp = options['require_path']
        require(rp)
      end
      if lp = options['load_path']
        load(lp)
      end

      pa_class = Ruote.constantize(class_name)
      pa_m = pa_class.instance_methods

      if irt && ! (pa_m.include?(irt.to_s) || pa_m.include?(irt.to_sym))
        return nil
      end

      pa = if pa_class.instance_method(:initialize).arity > 0
        pa_class.new(options)
      else
        pa_class.new
      end
      pa.context = @context if pa.respond_to?(:context=)

      pa
    end

    # Return a list of names (regex) for the registered participants
    #
    def names

      get_list['list'].collect { |re, pa| re }
    end

    # Shuts down the 'instantiated participants' (engine worker participants)
    # if they respond to #shutdown.
    #
    def shutdown

      @instantiated_participants.each { |re, pa|
        pa.shutdown if pa.respond_to?(:shutdown)
      }
    end

    # Used by Engine#participant_list
    #
    # Returns a representation of this participant list as an array of
    # ParticipantEntry instances.
    #
    def list

      get_list['list'].collect { |e| ParticipantEntry.new(e) }
    end

    # Used by Engine#participant_list=
    #
    # Takes as input an array of ParticipantEntry instances and updates
    # this participant list with it.
    #
    # See ParticipantList#list
    #
    def list= (pl)

      list = get_list
      list['list'] = pl.collect { |pe| pe.to_a }

      if r = @context.storage.put(list)
        #
        # put failed, have to redo it
        #
        list= (pl)
      end
    end

    protected

    # Fetches and returns the participant list in the storage.
    #
    def get_list

      @context.storage.get_configuration('participant_list') ||
        { 'type' => 'configurations',
          '_id' => 'participant_list',
          'list' => [] }
    end

    # Returns an array of all the classes in the ObjectSpace that include the
    # Ruote::LocalParticipant module.
    #
    def local_participant_classes

      ObjectSpace.each_object(Class).inject([]) { |a, c|
        a << c if c.include?(Ruote::LocalParticipant)
        a
      }
    end
  end

  #
  # A helper class, for ParticipantList#list, which returns a list (order
  # matters) of ParticipantEntry instances.
  #
  # See Engine#participant_list
  #
  class ParticipantEntry

    attr_accessor :regex, :classname, :options

    def initialize (a)
      @regex = a.first
      if a.last.is_a?(Array)
        @classname = a.last.first
        @options = a.last.last
      else
        @classname = a.last
        @options = nil
      end
    end

    def to_a
      @classname.match(/^inpa\_/) ?
        [ @regex, @classname ] :
        [ @regex, [ @classname, @options ] ]
    end

    def to_s
      "/#{@regex}/ ==> #{@classname} #{@opts.inspect}"
    end
  end
end

