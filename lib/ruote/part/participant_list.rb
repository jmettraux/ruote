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


require 'ruote/engine/context'
require 'ruote/part/block_participant'


module Ruote

  #
  # Tracking participants to [business] processes.
  #
  # (Warning, the register/unregsiter methods are not thread-safe)
  #
  class ParticipantList

    include EngineContext

    attr_reader :list


    def initialize

      @list = []
    end

    # Registers participant (and returns it)
    #
    def register (name, participant, options, block)

      options[:participant_name] = name

      entry = [
        name.is_a?(Regexp) ? name : Regexp.new("^#{name}$"),
        prepare(participant, options, block)
      ]

      position = options[:position] || :last

      case position
        when :last then @list << entry
        when :first then @list.unshift(entry)
        when Fixnum then @list.insert(position, entry)
        else raise "cannot insertion participant at position '#{position}'"
      end

      entry.last
    end

    def lookup (participant_name)

      re, pa = @list.find { |re, pa| re.match(participant_name) }
      pa
    end

    def unregister (name_or_participant)

      name_or_participant = name_or_participant.to_s \
        if name_or_participant.is_a?(Symbol)

      entry = @list.find do |re, pa|

        name_or_participant.is_a?(String) ?
          re.match(name_or_participant) :
          (pa == name_or_participant)
      end

      @list.delete(entry)
    end

    def shutdown

      @list.each { |re, pa| pa.shutdown if pa.respond_to?(:shutdown) }
    end

    protected

    def prepare (p, opts, block)

      p = if block
        BlockParticipant.new(block, opts)
      elsif p.class == Class
        p.new(opts)
      else
        p
      end

      p.context = @context if p.respond_to?(:context=)

      p
    end
  end
end

