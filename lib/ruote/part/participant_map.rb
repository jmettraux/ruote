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


require 'ruote/engine/context'

parpath = File.dirname(__FILE__)

Dir.new(parpath).entries.select { |p|
  p.match(/^.*_participant\.rb$/)
}.each { |p|
  require parpath + '/' + p
}


module Ruote

  class ParticipantMap

    include EngineContext

    attr_reader :map


    def initialize

      @map = []
    end

    def context= (c)

      @context = c
      wqueue.add_observer(:participants, self)
    end

    def register (name, participant, options, block)

      entry = [
        name.is_a?(Regexp) ? name : Regexp.new("^#{name}$"),
        prepare(participant, options, block)
      ]

      position = options[:position] || :last

      case position
        when :last then @map << entry
        when :first then @map.unshift(entry)
        when Fixnum then @map.insert(position, entry)
        else raise "cannot insertion participant at position '#{position}'"
      end
    end

    def lookup (participant_name)

      r, p = @map.find { |r, p| r.match(participant_name) }
      p
    end

    protected

    def receive (eclass, emsg, eargs)

      case emsg
        when :dispatch then dispatch(eargs[:participant], eargs[:workitem])
        when :cancel then dispatch(eargs[:participant_name], eargs[:fei])
      end
    end

    def dispatch (participant, workitem)

      participant.consume(workitem)
    end

    def cancel (participant_name, fei)

      p :cancel # TODO
    end

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

