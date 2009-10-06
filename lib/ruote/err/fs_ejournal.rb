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


require 'monitor'
require 'ruote/err/ejournal'


module Ruote

  #
  # File based error journal.
  #
  class FsErrorJournal < HashErrorJournal

    def context= (c)

      @context = c
      subscribe(:errors)

      @path = @context[:ejournal_path] || workdir + '/ejournal'
      @path = File.expand_path(@path)
      FileUtils.makedirs(@path) unless File.exist?(@path)

      @monitor = Monitor.new
        #
        # writes are all workqueue driven, but since reads are out of this
        # cycle, a monitor is necessary (to prevent reads to access inconsistent
        # data).
    end

    # Returns the list of errors for a given process instance
    #
    def process_errors (wfid, raw=false)

      @monitor.synchronize do

        errs = (YAML.load_file(path_for(wfid)) rescue {})

        raw ? errs : errs.collect { |e| ProcessError.new(e) }
      end
    end

    # Removes the errors corresponding to a process.
    #
    # Returns true if there was actually some errors that got purged.
    #
    def purge_process (wfid)

      @monitor.synchronize do
        begin
          File.delete(path_for(wfid))
          true
        rescue Exception => e
          false
        end
      end
    end

    # Clears all errors. Mostly used by the test framework.
    #
    def purge!

      Dir[File.join(@path, '*')].each { |d| FileUtils.rm_rf(d) }
    end

    protected

    def path_for (wfid)

      File.join(@path, "#{wfid}_ejournal.yaml")
    end

    def save (wfid, errors)

      File.open(path_for(wfid), 'w') { |f| f.puts(errors.to_yaml) }
    end

    def remove (fei)

      @monitor.synchronize do

        errors = process_errors(fei.parent_wfid, true)
          # re-entry...

        err = errors.find { |e| e[:fei] == fei }

        return unless err

        errors.delete(err)

        save(fei.parent_wfid, errors)
      end
    end

    def record (fei, eargs)

      @monitor.synchronize do

        errors = process_errors(fei.parent_wfid, true)
          # re-entry...

        errors = errors.inject({}) { |h, e| h[e[:fei]] = e; h }
        errors[fei] = eargs

        save(fei.parent_wfid, errors.values)
      end
    end
  end
end

