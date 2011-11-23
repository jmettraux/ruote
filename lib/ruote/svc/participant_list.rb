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


require 'sourcify'
require 'ruote/part/local_participant'
require 'ruote/part/block_participant'
require 'ruote/part/code_participant'


module Ruote

  #
  # Tracking participants to [business] processes.
  #
  # The methods here are mostly called via the engine (registering /
  # unregistering participants) and via the dispatch_pool (when handing
  # workitems to participants).
  #
  class ParticipantList

    # Vanilla service #initialize.
    #
    def initialize(context)

      @context = context
    end

    # Used by #register and by Ruote::ParticipantRegistrationProxy
    #
    def to_entry(name, participant, options, block)

      raise(
        ArgumentError.new(
          "can only accept strings (classnames) or classes as participant arg")
      ) unless [ String, Class, NilClass ].include?(participant.class)

      klass = (participant || Ruote::BlockParticipant).to_s

      options = options.inject({}) { |h, (k, v)|

        h[k.to_s] = case v
          when Symbol then v.to_s
          when Proc then v.to_raw_source
          else v
        end

        h
      }

      if block
        options['on_workitem'] = block.to_raw_source
        @context.treechecker.block_check(options['on_workitem'])
      end

      [
        (name.is_a?(Regexp) ? name : Regexp.new("^#{name}$")).source,
        [ klass, options ]
      ]
    end

    # Registers a participant. Called by Engine#register_participant.
    #
    def register(name, participant, options, block)

      entry = to_entry(name, participant, options, block)

      key = entry.first
      options = entry.last.last

      list = get_list

      position = options['position'] || options['pos'] || 'last'

      if position == 'before'

        position = list['list'].index { |e| e.first == key } || -1

      elsif position == 'after'

        position = (list['list'].rindex { |e| e.first == key } || -2) + 1

      elsif position == 'over'

        position = list['list'].index { |e| e.first == key } || -1
        list['list'].delete_at(position) unless position == -1

      elsif options.delete('override') != false

        list['list'].delete_if { |e| e.first == key }
          # enforces only one instance of a participant per key/regex
      end

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
        return register(name, participant, options, block)
      end

      if entry.last.first == 'Ruote::StorageParticipant'
        Ruote::StorageParticipant.new(@context)
      else
        nil
      end
    end

    # Removes a participant, given via its name or directly from this
    # participant list.
    #
    # Called usually by Engine#unregister_participant.
    #
    def unregister(name_or_participant)

      code = nil
      entry = nil
      list = get_list

      name_or_participant = name_or_participant.to_s

      entry = list['list'].find { |re, pa| name_or_participant.match(re) }

      return nil unless entry

      code = entry.last if entry.last.is_a?(String)

      list['list'].delete(entry)

      if r = @context.storage.put(list)
        #
        # put failed, have to redo it
        #
        return unregister(name_or_participant)
      end

      entry.first
    end

    # Returns a participant instance, or nil if there is no participant
    # for the given participant name.
    #
    # Mostly a combination of #lookup_info and #instantiate.
    #
    def lookup(participant_name, workitem, opts={})

      pinfo = participant_name.is_a?(String) ?
        lookup_info(participant_name, workitem) : participant_name

      pinfo ?
        instantiate(pinfo, opts) : nil
    end

    # Given a participant name, returns
    #
    # Returns nil if there is no participant registered that covers the given
    # participant name.
    #
    def lookup_info(pname, workitem)

      wi = workitem ?
        Ruote::Workitem.new(workitem.merge('participant_name' => pname)) :
        nil

      get_list['list'].each do |regex, pinfo|

        next unless pname.match(regex)

        return pinfo if workitem.nil?

        pa = instantiate(pinfo, :if_respond_to? => :accept?)

        return pinfo if pa.nil?
        return pinfo if Ruote.participant_send(pa, :accept?, 'workitem' => wi)
      end

      # nothing found...

      nil
    end

    # Returns an instance of a participant
    #
    def instantiate(pinfo, opts={})

      pa_class_name, options = pinfo

      if rp = options['require_path']
        require(rp)
      end
      if lp = options['load_path']
        load(lp)
      end

      pa_class = Ruote.constantize(pa_class_name)
      pa_m = pa_class.instance_methods

      irt = opts[:if_respond_to?]

      if irt && ! (pa_m.include?(irt.to_s) || pa_m.include?(irt.to_sym))
        return nil
      end

      initialize_participant(pa_class, options)
    end

    def initialize_participant(klass, options)

      participant = if klass.instance_method(:initialize).arity == 0
        klass.new
      else
        klass.new(options)
      end

      participant.context = @context if participant.respond_to?(:context=)

      participant
    end

    # Return a list of names (regex) for the registered participants
    #
    def names

      get_list['list'].collect { |re, pa| re }
    end

    # Calls #shutdown on any participant that sports this method.
    #
    def shutdown

      get_list['list'].each do |re, (kl, op)|

        kl = (Ruote.constantize(kl) rescue nil)

        if (kl.instance_method(:shutdown) rescue false)
          initialize_participant(kl, op).shutdown
        end
      end
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
    def list=(pl)

      list = get_list

      list['list'] = pl.collect { |e|
        ParticipantEntry.read(e)
      }.collect { |e|
        e[0] = e[0].source if e[0].is_a?(Regexp)
        e
      }

      if r = @context.storage.put(list)
        #
        # put failed, have to redo it
        #
        self.list=(pl)
      end
    end

    # Clears this participant list.
    #
    # Used by Engine#register(&block)
    #
    def clear

      self.list=([])
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

    #--
    # Returns an array of all the classes in the ObjectSpace that include the
    # Ruote::LocalParticipant module.
    #
    #def local_participant_classes
    #  ObjectSpace.each_object(Class).inject([]) { |a, c|
    #    a << c if c.include?(Ruote::LocalParticipant)
    #    a
    #  }
    #end
    #++
  end

  #
  # A helper class, for ParticipantList#list, which returns a list (order
  # matters) of ParticipantEntry instances.
  #
  # See Engine#participant_list
  #
  class ParticipantEntry

    attr_accessor :regex, :classname, :options

    def initialize(a)
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

      [ @regex, [ @classname, @options ] ]
    end

    def to_s

      "/#{@regex}/ ==> #{@classname} #{@options.inspect}"
    end

    # Makes sense of whatever is given to it, returns something like
    #
    #   [ regex, [ klass, opts ] ]
    #
    def self.read(elt)

      return elt.to_a if elt.is_a?(ParticipantEntry)

      if elt.is_a?(Hash)

        options = elt['options'] || elt.reject { |k, v|
          %w[ name regex regexp class classname ].include?(k)
        }

        name = elt.find { |k, v| v == nil }
        if name
          name = name.first
          elt.delete(name)
          options.delete(name)
        end
        name = name || elt['name']
        name = Ruote.regex_or_s(name)

        regex = name
        unless name
          regex = Ruote.regex_or_s(elt['regex'] || elt['regexp'])
          regex = regex.is_a?(String) ? Regexp.new(regex) : regex
        end

        klass = (elt['classname'] || elt['class']).to_s

        return [ regex, [ klass, options ] ]
      end

      # else elt is a Array

      if elt.size == 3
        return [ Ruote.regex_or_s(elt[0]), [ elt[1].to_s, elt[2] ] ]
      end

      [ Ruote.regex_or_s(elt[0]), elt[1] ]
    end
  end
end

