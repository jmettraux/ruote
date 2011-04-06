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


require 'open-uri'

require 'ruote/part/local_participant'


module Ruote

  #
  # TODO
  #
  class RevParticipant

    include LocalParticipant

    def initialize(opts=nil)

      @dir = opts['dir']

      raise ArgumentError.new(
        "missing option :dir for #{self.class}"
      ) unless @dir
    end

    #
    # No operation : simply replies immediately to the engine.
    #
    def consume(wi)

      rev = wi.params['revision'] || wi.params['rev']

      consumed = false

      [
        [ wi.wf_name, wi.wf_revision, wi.participant_name, rev ],
        [ wi.wf_name, wi.wf_revision, wi.participant_name ],
        [ wi.wf_name, '', wi.participant_name ],
        [ wi.participant_name, rev ],
        [ wi.participant_name ],
      ].each do |fname|

        fname = File.join(@dir, "#{fname.compact.join('__')}.rb")
        next unless File.exist?(fname)

        cpart = Class.new
        cpart.send(:include, Ruote::LocalParticipant)
        cpart.module_eval(File.read(fname))
        part = cpart.new
        part.context = @context

        part.consume(wi)
        consumed = true
        break
      end

      raise ArgumentError.new(
        "couldn't find code for participant #{wi.participant_name} " +
        "in dir #{@dir}"
      ) unless consumed
    end

    def cancel(fei, flavour)

      # TODO
    end
  end
end

