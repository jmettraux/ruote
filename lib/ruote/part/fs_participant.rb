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

  class FsParticipant

    include EngineContext
    include LocalParticipant

    include Enumerable

    def initialize (opts)

      @name = neutralize(opts[:participant_name])
    end

    def context= (c)

      @context = c

      @path =
        @context[:fs_participant_path] ||
        File.join(workdir, '/fs_participants')

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
    end

    # Returns all the workitems stored here that have a given wfid
    #
    def by_wfid (wfid)

      Dir.glob(File.join(@path, "*_#{wfid}_*.yaml")).collect do |path|
        YAML.load_file(path)
      end
    end

    protected

    def path_for (fei)

      File.join(
        @path, "#{@name}__#{fei.engine_id}_#{fei.wfid}_#{fei.expid}.yaml")
    end

    def neutralize (s)

      s.to_s.gsub(/[ \/:;\*\\\+\?]/, '_')
    end
  end
end

