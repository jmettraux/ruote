#
#--
# Copyright (c) 2007-2009, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

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
