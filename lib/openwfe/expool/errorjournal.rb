#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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

require 'openwfe/service'
require 'openwfe/omixins'
require 'openwfe/rudefinitions'


module OpenWFE

    #
    # Encapsulating process error information.
    #
    # Instances of this class may be used to replay_at_error
    #
    class ProcessError

        #
        # When did the error occur.
        #
        attr_reader :date

        #
        # The FlowExpressionId instance uniquely pointing at the expression
        # which 'failed'.
        #
        attr_reader :fei

        #
        # Generally something like :apply or :reply
        #
        attr_reader :message

        #
        # The workitem accompanying the message (apply(workitem) /
        # reply (workitem)).
        #
        attr_reader :workitem

        #
        # The String stack trace of the error.
        #
        attr_reader :stacktrace

        #
        # The error class (String) of the top level error
        #
        attr_reader :error_class

        def initialize (*args)

            @date = Time.new
            @fei, @message, @workitem, @error_class, @stacktrace = args
        end

        #
        # Returns the parent workflow instance id (process id) of this
        # ProcessError instance.
        #
        def wfid
            @fei.parent_wfid
        end

        alias :parent_wfid :wfid

        #
        # Produces a human readable version of the information in the
        # ProcessError instance.
        #
        def to_s
            s = ""
            s << "-- #{self.class.name} --\n"
            s << "     date :        #{@date}\n"
            s << "     fei :         #{@fei}\n"
            s << "     message :     #{@message}\n"
            s << "     workitem :    ...\n"
            s << "     error_class : #{@error_class}\n"
            s << "     stacktrace :  #{@stacktrace[0, 80]}\n"
            s
        end

        #
        # Returns a hash
        #
        def hash
            to_s.hash
                #
                # a bit costly but as it's only used by resume_process()...
        end

        #
        # Returns true if the other instance is a ProcessError and is the
        # same error as this one.
        #
        def == (other)
            return false unless other.is_a?(ProcessError)
            return to_s == other.to_s
                #
                # a bit costly but as it's only used by resume_process()...
        end
    end

    #
    # This is a base class for all error journal, don't instantiate,
    # work rather with InMemoryErrorJournal (only for testing envs though),
    # or YamlErrorJournal.
    #
    class ErrorJournal < Service
        include OwfeServiceLocator
        include FeiMixin

        def initialize (service_name, application_context)

            super

            get_expression_pool.add_observer :error do |event, *args|
                #
                # logs each error occurring in the expression pool

                begin

                    record_error(ProcessError.new(*args))

                rescue Exception => e
                    lwarn { "(failed to record error : #{e})" }
                    lwarn { "*** process error : \n" + args.join("\n") }
                end
            end

            get_expression_pool.add_observer :terminate do |event, *args|
                #
                # removes error log when a process terminates

                fei = args[0].fei

                remove_error_log fei.wfid \
                    if fei.is_in_parent_process?
            end
        end

        #
        # Returns true if the given wfid (or fei) (process instance id)
        # has had errors.
        #
        def has_errors? (wfid)

            get_error_log(wfid).size > 0
        end

        #--
        #
        # Commented out : has no real value
        #
        # Replays the given process instance (wfid or fei) at its last
        # recorded error.
        #
        # There is an optional 'offset' parameter. Its default value is '0'.
        # Which means that the replay will occur at the last error.
        #
        #     ejournal.replay_at_last_error('20070630-hiwakuzara', 1)
        #
        # Will replay a given process instance at its 1 to last error.
        #
        #def replay_at_last_error (wfid, offset=0)
        #    wfid = extract_wfid(wfid)
        #    log = get_error_log(wfid)
        #    index = (-1 - offset)
        #    error = log[index]
        #    raise "no error for process '#{wfid}' at offset #{offset}" \
        #        unless error
        #    replay_at_error error
        #end
        #++

        #
        # A utility method : given a list of errors, will make sure that for
        # each flow expression only one expression (the most recent) will get
        # listed.
        # Returns a list of errors, from the oldest to the most recent.
        #
        # Could be useful when considering a process where multiple replay
        # attempts failed.
        #
        def ErrorJournal.reduce_error_list (errors)

            h = {}

            errors.each do |e|
                h[e.fei] = e
                    #
                    # last errors do override previous errors for the
                    # same fei
            end

            h.values.sort do |error_a, error_b|
                error_a.date <=> error_b.date
            end
        end
    end

    #
    # Stores all the errors in a hash... For testing purposes only, like
    # the InMemoryExpressionStorage.
    #
    class InMemoryErrorJournal < ErrorJournal

        def initialize (service_name, application_context)

            super

            @per_processes = {}
        end

        #
        # Returns a list (older first) of the errors for a process
        # instance identified by its fei or wfid.
        #
        # Will return an empty list if there a no errors for the process
        # instances.
        #
        def get_error_log (wfid)

            wfid = extract_wfid wfid, true
            @per_processes[wfid] or []
        end

        #
        # Removes the error log for a process instance.
        #
        def remove_error_log (wfid)

            wfid = extract_wfid wfid, true
            @per_processes.delete(wfid)
        end

        #
        # Removes a list of errors from the error journal.
        #
        # The 'errors' parameter may be a single error (instead of an array).
        #
        def remove_errors (wfid, errors)

            errors = Array(errors)

            log = get_error_log wfid

            errors.each do |e|
                log.delete e
            end
        end

        #
        # Reads all the error logs currently stored.
        # Returns a hash wfid --> error list.
        #
        def get_error_logs

            @per_processes
        end

        protected

            def record_error (error)

                (@per_processes[error.wfid] ||= []) << error
                    # not that unreadable after all...
            end
    end

    #
    # A Journal that only keep track of error in process execution.
    #
    class YamlErrorJournal < ErrorJournal

        attr_reader :workdir

        def initialize (service_name, application_context)

            require 'openwfe/storage/yamlcustom'
                # making sure this file has been required at this point
                # this yamlcustom thing prevents the whole OpenWFE ecosystem
                # to get serialized :)

            super

            @workdir = get_work_directory + "/ejournal"
            #@workdir = File.expand_path @workdir

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

            path = get_path wfid

            return [] unless File.exist?(path)

            read_error_log_from path
        end

        #
        # Copies the error log of a process instance to a give path (and
        # filename).
        #
        # Could be useful when one has to perform replay operations and wants
        # to keep a copy of the original error[s].
        #
        def copy_error_log_to (wfid, path)

            original_path = get_path wfid
            FileUtils.copy_file original_path, path
        end

        #
        # Reads an error log from a specific file (possibly as copied over
        # via copy_error_log_to()).
        #
        def read_error_log_from (path)

            raise "no error log file at #{path}" unless File.exist?(path)

            File.open(path) do |f|
                s = YAML.load_stream f
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

            path = get_path wfid

            File.delete(path) if File.exist?(path)
        end

        #
        # Removes a list of errors from this error journal.
        #
        def remove_errors (wfid, errors)

            errors = Array(errors)

            # load all errors

            log = get_error_log wfid

            # remove the given errors

            errors.each do |e|
                log.delete e
            end

            # rewrite error file

            path = get_path wfid

            if log.size > 0

                File.open(path, "w") do |f|
                    log.each do |e|
                        f.puts e.to_yaml
                    end
                end
            else

                File.delete path
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

                log = read_error_log_from path
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

                path = get_path error.fei

                dirpath = File.dirname path

                FileUtils.mkdir_p(dirpath) unless File.exist?(dirpath)

                File.open path, "a+" do |f|
                    f.puts error.to_yaml
                end
            end

            #
            # Returns the path to the error log file of a specific process
            # instance.
            #
            def get_path (fei_or_wfid)

                @workdir + "/" + extract_wfid(fei_or_wfid, true) + ".ejournal"
            end
    end
end
