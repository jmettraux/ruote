#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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


require 'find'
require 'fileutils'

require 'openwfe/expool/errorjournal'


module OpenWFE

  #
  # A Journal that only keep track of error in process execution.
  #
  class YamlErrorJournal < ErrorJournal

    attr_reader :workdir

    def initialize (service_name, application_context)

      super

      @workdir = get_work_directory + '/ejournal'
      #@workdir = File.expand_path(@workdir)

      FileUtils.makedirs(@workdir) unless File.exist?(@workdir)
    end

    #
    # Returns a list (older first) of the errors for a process
    # instance identified by its fei or wfid.
    #
    # Will return an empty list if there a no errors for the process
    # instances.
    #
    def get_error_log (wfid)

      path = get_path(wfid)

      return [] unless File.exist?(path)

      read_error_log_from(path)
    end

    #
    # Copies the error log of a process instance to a give path (and
    # filename).
    #
    # Could be useful when one has to perform replay operations and wants
    # to keep a copy of the original error[s].
    #
    def copy_error_log_to (wfid, path)

      original_path = get_path(wfid)
      FileUtils.copy_file(original_path, path)
    end

    #
    # Reads an error log from a specific file (possibly as copied over
    # via copy_error_log_to()).
    #
    def read_error_log_from (path)

      raise "no error log file at #{path}" unless File.exist?(path)

      File.open(path) do |f|
        s = YAML.load_stream(f)
        s.documents
      end
    end

    #
    # Removes the error log of a specific process instance.
    # Could be a good idea after a succesful replay operation.
    #
    # 'wfid' may be either a workflow instance id (String) either
    # a FlowExpressionId instance.
    #
    def remove_error_log (wfid)

      path = get_path(wfid)

      File.delete(path) if File.exist?(path)
    end

    #
    # Removes a list of errors from this error journal.
    #
    def remove_errors (wfid, errors)

      errors = Array(errors)

      # load all errors

      log = get_error_log(wfid)

      # remove the given errors

      errors.each { |e| log.delete(e) }

      # rewrite error file

      path = get_path wfid

      if log.size > 0

        File.open(path, 'w') do |f|
          log.each do |e|
            f.puts e.to_yaml
          end
        end
      else

        File.delete(path)
      end
    end

    #
    # Reads all the error logs currently stored.
    # Returns a hash wfid --> error list.
    #
    def get_error_logs

      result = {}

      Find.find(@workdir) do |path|

        next unless path.match(/\.ejournal$/)

        log = read_error_log_from(path)
        result[log.first.fei.wfid] = log
      end

      result
    end

    protected

      #
      # logs the error as a yaml string in an error log file
      # (there is one error log file per workflow instance).
      #
      def record_error (error)

        path = get_path(error.fei)

        dirpath = File.dirname(path)

        FileUtils.mkdir_p(dirpath) unless File.exist?(dirpath)

        File.open(path, 'a+') do |f|
          f.puts(error.to_yaml)
        end
      end

      #
      # Returns the path to the error log file of a specific process
      # instance.
      #
      def get_path (fei_or_wfid)

        "#{@workdir}/#{extract_wfid(fei_or_wfid, true)}.ejournal"
      end
  end
end
