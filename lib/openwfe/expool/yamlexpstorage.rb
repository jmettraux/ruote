#
#--
# Copyright (c) 2006-2008, Nicolas Modryzk and John Mettraux, OpenWFE.org
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
# Nicolas Modrzyk at openwfe.org
# John Mettraux at openwfe.org
#

require 'openwfe/utils'
require 'openwfe/storage/yamlcustom'
require 'openwfe/storage/yamlfilestorage'
require 'openwfe/expool/threadedexpstorage'

require 'openwfe/expressions/flowexpression'
#require 'openwfe/expressions/raw_xml'
  #--
  # making sure classes in those files are loaded
  # before their yaml persistence is tuned
  # (else the reopening of the class is interpreted as
  # a definition of the class...)
  #++


module OpenWFE

  #
  # YAML expression storage. Expressions (atomic pieces of process instances)
  # are stored in a hierarchy of YAML files.
  #
  class YamlFileExpressionStorage < YamlFileStorage
    include OwfeServiceLocator
    include ExpressionStorageBase

    def initialize (service_name, application_context)

      super service_name, application_context, '/expool'

      observe_expool
    end

    #
    # Find expressions matching various criteria.
    # (See Engine#list_process_status for an explanation)
    #
    def find_expressions (options)

      wfid_prefix = options[:wfid_prefix]
      wfid_regex = nil
      wfid_regex = Regexp.new("^"+wfid_prefix) if wfid_prefix

      options.delete :wfid_prefix
        # no need to check this in further does_match? calls

      result = []

      each_object_path do |path|

        unless path[-23..-1] == 'engine_environment.yaml'

          a = self.class.split_file_path path

          next unless a
            # not an expression file

          wfid = a[0]

          next if wfid_regex and (not wfid_regex.match(wfid))
        end

        fexp = load_object path

        next unless does_match?(options, fexp)

        result << fexp
      end

      result
    end

    def fetch_root (wfid)

      fei = FlowExpressionId.new
      fei.wfid = wfid
      fei.expid = "0"
      fei.expression_name = "process-definition"

      root = self[fei]

      return root if root

      #
      # direct hit missed, scanning...

      each_object_path(compute_dir_path(wfid)) do |p|

        a = self.class.split_file_path p
        next unless a

        next unless a[0] == wfid

        fexp = load_object p

        return fexp if fexp.is_a?(DefineExpression)
      end

      nil
    end

    #
    # Returns a human-readable list of the current YAML file paths.
    # (one expression per path).
    #
    def to_s

      s = "\n\n==== #{self.class} ===="
      s << "\n"
      each_object_path do |path|
        s << path
        s << "\n"
      end
      s << "==== . ====\n"
      s
    end

    #
    # Returns nil (if the path doesn't match an stored expression path)
    # or an array [ workflow_instance_id, expression_id, expression_name ].
    #
    # This is a class method (not an instance one).
    #
    def self.split_file_path (path)

      md = path.match %r{.*/(.*)__([\d.]*)_(.*).yaml}
      return nil unless md
      [ md[1], md[2], md[3] ]
    end

    protected

      def compute_dir_path (wfid)

        wfid = FlowExpressionId.to_parent_wfid wfid

        a_wfid = get_wfid_generator.split_wfid wfid

        @basepath + a_wfid[-2] + "/" + a_wfid[-1] + "/"
      end

      def compute_file_path (fei)

        return @basepath + "/engine_environment.yaml" \
          if fei.workflow_instance_id == "0"

        wfid = fei.parent_workflow_instance_id

        compute_dir_path(wfid) +
        fei.workflow_instance_id + "__" +
        fei.expression_id + "_" +
        fei.expression_name + ".yaml"
      end

      #--
      # Returns true if the path points to a file containing an
      # expression whose name is in the list of expression names
      # corresponding to the given kind (class) of expressions.
      #
      #def matches (path, kind)
      #  exp_names = get_expression_map.get_expression_names(kind)
      #  exp_names.each do |exp_name|
      #    return true \
      #      if OpenWFE::ends_with(path, "_#{exp_name}.yaml")
      #  end
      #  false
      #end
      #++
  end

  #
  # With this extension of YmalFileExpressionStorage, persistence occurs
  # in a separate thread, for a snappier response.
  #
  class ThreadedYamlFileExpressionStorage < YamlFileExpressionStorage
    include ThreadedStorageMixin

    def initialize (service_name, application_context)

      super

      start_queue
    end
  end
end
