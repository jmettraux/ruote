#
#--
# Copyright (c) 2009, John Mettraux, OpenWFE.org
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

require 'fileutils'
require 'openwfe/expool/expstorage'
require 'openwfe/expool/threaded_expstorage'


module OpenWFE

  #
  # TODO : document me and :persist_as_yaml
  #
  class FsExpressionStorage
    include ServiceMixin
    include OwfeServiceLocator
    include ExpressionStorageBase

    #attr_accessor :persist_as_yaml

    def initialize (service_name, application_context)

      service_init(service_name, application_context)

      @basepath = get_work_directory + '/expool'
      @persist_as_yaml = (application_context[:persist_as_yaml] == true)
      @suffix = 'ruote'

      observe_expool
    end

    #
    # Stores an expression
    #
    def []= (fei, fexp)

      d, fn = filename_for(fei)

      FileUtils.mkdir_p(d) unless File.exist?(d)

      File.open("#{d}/#{fn}", 'w') { |f| f.write(encode(fexp)) }
    end

    #
    # Retrieves an expression
    #
    def [] (fei)

      fexp = load_fexp(filename_for(fei, true))
      fexp.application_context = @application_context if fexp
      fexp
    end

    #
    # Removes the expression from the storage
    #
    def delete (fei)

      FileUtils.rm_f(filename_for(fei, true))
    end

    #
    # Returns the count of expressions currently stored
    #
    def size

      Dir["#{@basepath}/**/*.#{@suffix}"].size
    end

    #
    # Finds expressions matching the given criteria (returns a list
    # of expressions).
    #
    # This methods is called by the expression pool, it's thus not
    # very "public" (not used directly by integrators, who should
    # just focus on the methods provided by the Engine).
    #
    # :wfid ::
    #   will list only one process,
    #   <tt>:wfid => '20071208-gipijiwozo'</tt>
    # :parent_wfid ::
    #   will list only one process, and its subprocesses,
    #   <tt>:parent_wfid => '20071208-gipijiwozo'</tt>
    # :consider_subprocesses ::
    #   if true, "process-definition" expressions
    #   of subprocesses will be returned as well.
    # :wfid_prefix ::
    #   allows your to query for specific workflow instance
    #   id prefixes. for example :
    #   <tt>:wfid_prefix => "200712"</tt>
    #   for the processes started in December.
    # :include_classes ::
    #   excepts a class or an array of classes, only instances of these
    #   classes will be returned. Parent classes or mixins can be
    #   given.
    #   <tt>:includes_classes => OpenWFE::SequenceExpression</tt>
    # :exclude_classes ::
    #   works as expected.
    # :wfname ::
    #   will return only the expressions who belongs to the given
    #   workflow [name].
    # :wfrevision ::
    #   usued in conjuction with :wfname, returns only the expressions
    #   with a given workflow revision.
    # :applied ::
    #   if this option is set to true, will only return the expressions
    #   that have been applied (exp.apply_time != nil).
    #
    def find_expressions (options={})

      dir = if wfid = options[:wfid]
        dir_for(wfid)
      else
        "#{@basepath}/**" # brute force
      end

      Dir["#{dir}/*.#{@suffix}"].inject([]) do |a, path|

        fexp = load_fexp(path)

        if fexp and does_match?(options, fexp)

          fexp.application_context = @application_context
          a << fexp
        end

        a
      end
    end

    #
    # Dangerous ! Nukes the whole work/expool/ dir
    #
    def purge

      FileUtils.rm_f(@basepath)
    end

    #
    # Fetches the root expression of a process instance
    #
    def fetch_root (wfid)

      dir = dir_for(wfid)

      fexps = Dir["#{dir}/*.#{@suffix}"].collect { |path| load_fexp(path) }

      root = fexps.find { |fexp|
        fexp.fei.expid == '0' &&
        fexp.fei.sub_instance_id == '' &&
        fexp.is_a?(OpenWFE::DefineExpression)
      }
      root.application_context = @application_context
      root
    end

    protected

    #
    # Encodes the flow expression (if the options :yaml_persistence is set
    # to true in the application context or via #yaml= will save as
    # YAML)
    #
    def encode (fexp)
      @persist_as_yaml ? fexp.to_yaml : Marshal.dump(fexp)
    end

    #
    # Loads the flow expression at the given path
    #
    def load_fexp (path)
      return nil unless File.exist?(path)
      File.open(path, 'r') { |f| decode(f.read) }
    end

    #
    # Decodes the content of a file (reads YAML or Marshall binary
    # indifferently)
    #
    def decode (s)
      s[0, 5] == '--- !' ? YAML.load(s) : Marshal.load(s)
    end

    #
    # Returns the directory path for a given workflow instance id
    #
    def dir_for (wfid)

      wfid = FlowExpressionId.to_parent_wfid(wfid)
      a_wfid = get_wfid_generator.split_wfid(wfid)

      "#{@basepath}/#{a_wfid[-2]}/#{a_wfid[-1]}"
    end

    #
    # Returns the pair dir / filename for an expression.
    # If the optional arg join is set to true, will return the full path
    # for the expression
    #
    def filename_for (fei, join=false)

      r = if fei.wfid == '0'
        [ @basepath, "engine_environment.#{@suffix}" ]
      else
        [
          dir_for(fei.wfid),
          "#{fei.workflow_instance_id}__#{fei.expression_id}_#{fei.expression_name}.#{@suffix}"
        ]
      end

      join ? "#{r.first}/#{r.last}" : r
    end

  end

  #
  # YAML expression storage. Expressions (atomic pieces of process instances)
  # are stored in a hierarchy of YAML files.
  #
  # DEPRECATED, use the plain FsExpressionStorage instead.
  #
  class YamlFileExpressionStorage < FsExpressionStorage

    def initialize (service_name, application_context)
      super
      @persist_as_yaml = true
      @suffix = 'yaml'
    end
  end

  #
  # With this extension of YmalFileExpressionStorage, persistence occurs
  # in a separate thread, for a snappier response.
  #
  # Will probably get deprecated soon.
  #
  class ThreadedYamlFileExpressionStorage < YamlFileExpressionStorage
    include ThreadedStorageMixin

    def initialize (service_name, application_context)
      super
      start_queue
    end
  end

end

