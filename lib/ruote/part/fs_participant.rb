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
require 'ruote/part/local_participant'


module Ruote

  #
  # This participant stores the workitems it receives in the filesystem (each
  # in its own file).
  #
  # By default, the location for these files is under work/fs_participants/ but
  # this can be changed by setting the :fs_participant_path of the engine
  # configuration (the hash passed at engine initialization) to some other
  # path (the participant takes care of mkdir'ing non-existent dirs).
  #
  # It's also possible to pass this :fs_participant_path as a participant
  # registration/instantiation option.
  #
  # An example of FsParticipant registration :
  #
  #   alfred = engine.register_participant :alfred, Ruote::FsParticipant
  #
  # Querying the participant for work[items] is quite straightforward :
  #
  #   puts "workitems count : #{alfred.size}"
  #
  #   alfred.each do |workitem|
  #     puts "#{workitem.fei.to_s} --> #{workitem.fields['customer']}"
  #   end
  #
  #   wi = alfred.first
  #   wi.fields['approved'] = true
  #
  #   alfred.reply(wi)
  #     # removes the workitem from 'alfred' and hands it back to the engine
  #     # so that it may resume its travel in the workflow instance.
  #
  class FsParticipant

    include EngineContext
    include LocalParticipant

    include Enumerable

    def initialize (opts)

      @name = neutralize(opts[:participant_name])

      @path = opts[:fs_participant_path]
    end

    def context= (c)

      @context = c

      @path ||=
        (@context[:fs_participant_path] ||
         File.join(workdir, '/fs_participants'))

      FileUtils.mkdir_p(@path) unless File.exist?(@path)
    end

    def consume (workitem)

      File.open(path_for(workitem.fei), 'w') { |f| YAML.dump(workitem, f) }
    end

    def cancel (fei, flavour)

      File.delete(path_for(fei))
    end

    def reply (workitem)

      File.delete(path_for(workitem.fei))
      reply_to_engine(workitem)
    end

    def size

      Dir.new(@path).entries.inject(0) do |i, path|
        path.match(/^#{@name}\_\_.*\.yaml$/) ? i + 1 : i
      end
    end

    def each (&block)

      Dir.new(@path).entries.each do |entry|
        next unless entry.match(/^#{@name}\_\_.*\.yaml$/)
        wi = YAML.load_file(File.join(@path, entry))
        block.call(wi)
      end
    end

    # A helper method for testing... Returns the first workitem in the
    # participant.
    #
    def first

      each { |workitem| return workitem }
      nil
    end

    # Returns all the workitems stored here that have a given wfid
    #
    def by_wfid (wfid)

      Dir.glob(File.join(@path, "*_#{wfid}_*.yaml")).collect do |path|
        YAML.load_file(path)
      end
    end

    # TODO : what about #all and #fist a la dm ?
    # TODO : include Enumerable ?

    protected

    def path_for (fei)

      File.join(
        @path, "#{@name}__#{fei.engine_id}_#{fei.wfid}__#{fei.expid}.yaml")
    end

    def neutralize (s)

      s.to_s.gsub(/[ \/:;\*\\\+\?]/, '_')
    end
  end
end

