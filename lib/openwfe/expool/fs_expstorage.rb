#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
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


require 'fileutils'
require 'openwfe/expool/expstorage'
require 'openwfe/expool/threaded_expstorage'


module OpenWFE

  #
  # Stores the expressions (the pieces of process instances) in the file system.
  #
  # By default uses Ruby Marshalling. If the options :persist_as_yaml is set
  # to true in the application context, YAML serialization will be used.
  # YAML is more portable than Ruby Marshalling, but considerably slower.
  #
  # The default (Ruby Marshalling) is recommended. If you need to migrate from
  # one version of Marshalling to the other, you can use work/pooltool.rb
  # to migrate the whole set of expressions from one format to the other.
  #
  class FsExpressionStorage
    include ServiceMixin
    include OwfeServiceLocator
    include ExpressionStorageBase

    attr_accessor :persist_as_yaml, :suffix
    attr_reader :basepath

    def initialize (service_name, application_context)

      service_init(service_name, application_context)

      @basepath =
        application_context[:expstorage_path] || get_work_directory + '/expool'

      @persist_as_yaml = (application_context[:persist_as_yaml] == true)
      @suffix = 'ruote'

      observe_expool
    end

    # Stores an expression
    #
    def []= (fei, fexp)

      d, fn = filename_for(fei)

      FileUtils.mkdir_p(d) unless File.exist?(d)

      File.open("#{d}/#{fn}", 'wb') { |f| f.write(encode(fexp)) }
    end

    # Retrieves an expression
    #
    def [] (fei)

      load_fexp(filename_for(fei, true))
    end

    # Removes the expression from the storage
    #
    def delete (fei)

      FileUtils.rm_f(filename_for(fei, true))
    end

    # Returns the count of expressions currently stored
    #
    def size

      Dir["#{@basepath}/**/*.#{@suffix}"].size
    end

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
        a << fexp if fexp and does_match?(options, fexp)
        a
      end
    end

    # An iterator on ALL expressions in the storage (only used by pooltool.ru)
    #
    def each

      return unless block_given?

      Dir["#{@basepath}/**/*.#{@suffix}"].each do |path|

        fexp = load_fexp(path)

        yield(fexp.fei, fexp)
      end
    end

    # Dangerous ! Nukes the whole work/expool/ dir
    #
    def purge

      FileUtils.rm_f(@basepath)
    end

    # Fetches the root expression of a process instance
    #
    def fetch_root (wfid)

      dir = dir_for(wfid)

      fexps = Dir["#{dir}/*.#{@suffix}"].collect { |path| load_fexp(path) }

      fexps.find { |fexp|
        fexp.fei.expid == '0' &&
        fexp.fei.sub_instance_id == '' &&
        fexp.is_a?(OpenWFE::DefineExpression)
      }
    end

    # Called by pooltool.ru
    #
    def close
      # nothing to do
    end

    protected

    # Encodes the flow expression (if the options :yaml_persistence is set
    # to true in the application context or via #yaml= will save as
    # YAML)
    #
    def encode (fexp)
      @persist_as_yaml ? fexp.to_yaml : Marshal.dump(fexp)
    end

    # Loads the flow expression at the given path
    #
    def load_fexp (path)

      return nil unless File.exist?(path)

      fexp = File.open(path, 'rb') { |f|
        s = f.read
        s[0, 5] == '--- !' ? YAML.load(s) : Marshal.load(s)
      }
      fexp.application_context = @application_context if fexp
      fexp
    end

    # Returns the directory path for a given workflow instance id
    #
    def dir_for (wfid)

      wfid = FlowExpressionId.to_parent_wfid(wfid)
      a_wfid = get_wfid_generator.split_wfid(wfid)

      "#{@basepath}/#{a_wfid[-2]}/#{a_wfid[-1]}"
    end

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
  # DEPRECATED.
  #
  class ThreadedYamlFileExpressionStorage < YamlFileExpressionStorage
    include ThreadedStorageMixin

    def initialize (service_name, application_context)
      super
      start_queue
    end
  end

end

