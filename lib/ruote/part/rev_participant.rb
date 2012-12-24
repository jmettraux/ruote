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


require 'open-uri'

require 'ruote/part/local_participant'


module Ruote

  #
  # This participant was born out of a suggestion from Jan Topiński in
  # http://groups.google.com/group/openwferu-users/browse_thread/thread/be20a5d861556fd8
  #
  # This participant is a gateway to code placed in a directory.
  #
  #   engine.register do
  #     toto, Ruote::RevParticipant, :dir => 'participants/toto/'
  #   end
  #
  # Then in the participants/toto/ dir :
  #
  #     /my_workflow__0.1__toto_0.6.rb
  #       # participant toto, workflow 'my_workflow' with revision '0.1'
  #     /my_workflow__toto.rb
  #       # participant toto, workflow 'my_workflow' any revision
  #     /toto_0.6.rb
  #       # participant toto with rev '0.6', any workflow
  #     /toto.rb
  #       # participant toto, any rev, any workflow
  #       # ...
  #
  # The scheme goes like :
  #
  #    /wf-name__wf-revision__participant-name__p-revision.rb
  #
  # The files themselves look like :
  #
  #   def consume(workitem)
  #     workitem.fields['kilroy'] = 'was here'
  #     reply_to_engine(workitem)
  #   end
  #
  # The file directly contains the classical participant methods defined at the
  # top level. #cancel, #accept?, #on_reply and of course #consume are OK.
  #
  #
  # Maybe, look at the tests for more clues :
  #
  #   https://github.com/jmettraux/ruote/blob/master/test/functional/ft_57_rev_participant.rb
  #
  # *Note* : It's probably not the best participant in a distributed context, it
  # grabs the code to execute from a directory. If you use it in a distributed
  # context, you'll have to make sure to synchronize the directory to each host
  # running a worker.
  #
  # *Warning* : this participant trusts the code it deals with, there is no
  # security check.
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

    def on_workitem

      Ruote.participant_send(
        lookup_code,
        [ :on_workitem, :consume ],
        'workitem' => workitem)
    end

    def on_cancel

      Ruote.participant_send(
        lookup_code,
        [ :on_cancel, :cancel ],
        'fei' => fei, 'flavour' => flavour)
    end

    #--
    #def accept?(workitem)
    #  part = lookup_code
    #  part.respond_to?(:accept?) ? part.accept?(workitem) : true
    #end
    #
    # Can't do this at this level, since it isn't the rev_participant's
    # own accept?, it has to go in lookup_code
    #++

    def on_reply

      part = lookup_code

      if part.respond_to?(:on_reply)
        Ruote.participant_send(part, :on_reply, 'workitem' => workitem)
      end
    end

    def rtimeout(workitem)

      part = lookup_code

      part.respond_to?(:rtimeout) ? part.rtimeout(workitem) : nil
    end

    protected

    # Maybe "lookup_real_participant_code" would be a better name...
    #
    def lookup_code

      wi = workitem

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

