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
  # This participant was born out of a suggestion from Jan Topiński in XXX
  #
  class RevParticipant

    include LocalParticipant

    # TODO : how to deal with >= and ~> ?

    def initialize(opts=nil)

      @dir = opts['dir']

      raise ArgumentError.new(
        "missing option :dir for #{self.class}"
      ) unless @dir
    end

    def consume(workitem)

      lookup_code(workitem).consume(workitem)
    end

    def cancel(fei, flavour)

      lookup_code(fei).cancel(fei, flavour)
    end

    #--
    #def accept?(workitem)
    #  part = lookup_code(workitem)
    #  part.respond_to?(:accept?) ? part.accept?(workitem) : true
    #end
    #
    # Can't do this at this level, since it isn't the rev_participant's
    # own accept?, it has to go in lookup_code
    #++

    def on_reply(workitem)

      part = lookup_code(workitem)
      part.on_reply(workitem) if part.respond_to?(:on_reply)
    end

    def rtimeout(workitem)

      part = lookup_code(workitem)

      part.respond_to?(:rtimeout) ? part.rtimeout(workitem) : nil
    end

    protected

    # Maybe "lookup_real_participant_code" would be a better name...
    #
    def lookup_code(wi_or_fei)

      wi = wi_or_fei.is_a?(Ruote::Workitem) ?  wi_or_fei : workitem(wi_or_fei)

      rev = wi.params['revision'] || wi.params['rev']

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

        next if part.respond_to?(:accept?) and (not part.accept?(wi))

        return part
      end

      raise ArgumentError.new(
        "couldn't find code for participant #{wi.participant_name} " +
        "in dir #{@dir}"
      )
    end
  end
end

