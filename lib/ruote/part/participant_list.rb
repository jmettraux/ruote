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


require 'ruote/part/block_participant'


module Ruote

  #
  # Tracking participants to [business] processes.
  #
  class ParticipantList

    attr_reader :list

    def initialize (context)

      @context = context
      @instantiated_participants = {}
      @list = nil
    end

    # Registers the participant.
    #
    # Called by the register_participant method of the engine.
    #
    def register (name, participant, options, block)

      #options[:participant_name] = name

      options = options.inject({}) { |h, (k, v)|
        h[k.to_s] = v.is_a?(Symbol) ? v.to_s : v
        h
      }

      list = get_list

      entry = if participant.is_a?(Class)
        [ participant.to_s, options ]
      else
        "#{name.class}/#{name.hash}"
      end

      entry = [ name.is_a?(Regexp) ? name : Regexp.new("^#{name}$"), entry ]

      position = options['position'] || 'last'
      case position
        when 'last' then list['list'] << entry
        when 'first' then list['list'].unshift(entry)
        when Fixnum then list['list'].insert(position, entry)
        else raise "cannot insertion participant at position '#{position}'"
      end

      if @context.storage.put(list)
        #
        # if put returns something it means the put failed, have to redo the
        # work...
        #
        return register(name, participant, options, block)
      end

      if entry.last.is_a?(String)

        participant = BlockParticipant.new(block, options) if block

        participant.context = @context if participant.respond_to?(:context=)
        @instantiated_participants[entry.last] = participant
        participant

      else

        nil
      end
    end

    def lookup (participant_name)

      re, pa = get_list['list'].find { |re, pa| re.match(participant_name) }

      return nil unless pa
      return @instantiated_participants[pa] if pa.is_a?(String)

      class_name, options = pa

      if rp = options['require_path']
        require(rp)
      end

      Ruote.constantize(class_name).new(options)
    end

    #def unregister (name_or_participant)
    #  name_or_participant = name_or_participant.to_s \
    #    if name_or_participant.is_a?(Symbol)
    #  entry = @list.find do |re, pa|
    #    name_or_participant.is_a?(String) ?
    #      re.match(name_or_participant) :
    #      (pa == name_or_participant)
    #  end
    #  @list.delete(entry)
    #end

    def shutdown

      @instantiated_participants.each { |re, pa|
        pa.shutdown if pa.respond_to?(:shutdown)
      }
    end

    protected

    def get_list

      @context.storage.get('participants', 'list') ||
        { 'type' => 'participants', '_id' => 'list', 'list' => [] }
    end

    #def prepare (pa, opts, block)
    #  pa = if pa.class == Class
    #    pa.new(opts.merge(:block => block))
    #  elsif block
    #    BlockParticipant.new(block, opts)
    #  else
    #    pa
    #  end
    #  pa.context = @context if pa.respond_to?(:context=)
    #  pa
    #end
  end
end

