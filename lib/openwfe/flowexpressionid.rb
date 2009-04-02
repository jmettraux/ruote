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
# Made in Japan and Costa Rica.
#++


require 'yaml'


module OpenWFE

  #
  # A FlowExpressionId is a unique identifier for a FlowExpression (an atomic
  # piece of a process instance).
  #
  # As workitems move through a workflow among the expressions and are emitted
  # outside of the business process engine via 'participant expressions',
  # these workitems are identified by the FlowExpressionId of the participant
  # expression that pushed them out (and is usually waiting for them
  # to come back).
  #
  class FlowExpressionId

    FIELDS = [
      :owfe_version,
      :engine_id,
      #:initial_engine_id,
      :workflow_definition_url,
      :workflow_definition_name,
      :workflow_definition_revision,
      :workflow_instance_id,
      :expression_name,
      :expression_id
    ]

    FIELDS.each { |f| attr_accessor f }

    alias :expid :expression_id
    alias :expid= :expression_id=

    alias :expname :expression_name
    alias :wfurl :workflow_definition_url
    alias :wfname :workflow_definition_name
    alias :wfrevision :workflow_definition_revision

    #
    # a trick : returns self...
    #
    def fei
      self
    end

    #
    # Returns a String that can be used to identify the FlowExpression[Id]
    # in a storage.
    #
    def as_string_key
      "#{@workflow_instance_id} #{@expression_name} #{@expression_id}"
    end

    #
    # This method return @workflow_instance_id. If parent is set to
    # true, if will return the same result as
    # parent_workflow_instance_id().
    #
    def wfid (parent=false)

      if parent
        parent_workflow_instance_id
      else
        workflow_instance_id
      end
    end
    alias :wfid= :workflow_instance_id=

    #
    # the old 'initial_engine_id' is now deprecated, the methods
    # are still around though.
    #
    def initial_engine_id= (s)

      # discard silently
    end
    def initial_engine_id

      @engine_id
    end

    #
    # Overrides the classical to_s()
    #
    def to_s

      "(fei #{@owfe_version} #{@engine_id} #{wfurl} #{wfname} #{wfrevision} #{wfid} #{expname} #{expid})"
    end

    #
    # Returns a hash version of this FlowExpressionId instance.
    #
    def to_h

      FIELDS.inject({}) { |r, f| r[f] = instance_variable_get("@#{f.to_s}"); r }
    end

    #
    # Rebuilds a FlowExpressionId from its Hash representation.
    #
    def self.from_h (h)

      FIELDS.inject(FlowExpressionId.new) do |fei, f|
        fei.instance_variable_set("@#{f}", h[f] || h[f.to_s]); fei
      end
    end

    #
    # Builds a new FlowExpressionId out of a hash (overriding some defaults)
    #
    def self.new_fei (h={})

      from_h({
        :owfe_version => OPENWFERU_VERSION,
        :engine_id => 'engine',
        :workflow_definition_url => 'no-url',
        :workflow_definition_name => 'no-name',
        :workflow_definition_revision => '0',
        :workflow_instance_id => '-1',
        :expression_name => 'no-exp',
        :expression_id => '0'
      }.merge(h))
    end

    #
    # full blown hash
    #
    def hash

      to_s.hash
    end

    #
    # short hash (used by the cached expression storage among others)
    #
    def short_hash

      "#{wfid} #{expid} #{expname}".hash
    end

    def == (other)

      return false unless other.is_a?(FlowExpressionId)

      #return self.to_s == other.to_s
        # no perf gain

      @workflow_instance_id == other.workflow_instance_id and
      @expression_id == other.expression_id and
      @workflow_definition_url == other.workflow_definition_url and
      @workflow_definition_revision == other.workflow_definition_revision and
      @workflow_definition_name == other.workflow_definition_name and
      @expression_name == other.expression_name and
      @owfe_version == other.owfe_version and
      @engine_id == other.engine_id
      #@initial_engine_id == other.initial_engine_id
        #
        # Made sure to put on top of the 'and' the things that
        # change the most...
    end

    #
    # Returns true if this other FlowExpressionId is nested within
    # this one.
    #
    # For example (fei TestTag 3 20070331-goyunodabu 0.0.0 sequence)
    # is an ancestor of (fei TestTag 3 20070331-goyunodabu 0.0.0.1 redo)
    #
    # This current implementation doesn't cross the subprocesses
    # boundaries.
    #
    def ancestor_of? (other_fei)

      o = other_fei.dup
      o.expression_name = @expression_name
      o.expression_id = @expression_id
      return false unless self == o

      other_fei.expid[0, @expression_id.length] == @expression_id
    end

    #
    # Returns a deep copy of this FlowExpressionId instance.
    #
    def dup

      OpenWFE::fulldup(self)
    end

    alias eql? ==

    def to_debug_s
      "(fei #{wfname} #{wfrevision} #{wfid} #{expid} #{expname})"
    end

    #
    # Returns a very short string representation (fei wfid expid expname).
    #
    def to_short_s
      "(fei #{wfid} #{expid} #{expname})"
    end

    #--
    # Returns a URI escaped string with just the wfid and the expid, like
    # '20070917-dupibodasa__0.0.1'
    #
    # Useful for unique identifier in URIs.
    #
    #def to_web_s
    #  wid = wfid.gsub("\.", '_')
    #  eid = expid.gsub("\.", '_')
    #  URI.escape("#{wid}__#{eid}")
    #end
    #++

    #--
    # Splits the web fei into the workflow instance id and the expression
    # id.
    #def self.split_web_s (s)
    #  i = s.rindex('__')
    #  [ s[0..i-1].gsub("\_", '.'), s[i+2..-1].gsub("\_", '.') ]
    #end
    #++

    #
    # Yet another debugging method. Just returns the sub_instance_id and
    # the expression_id, in a string.
    #
    def to_env_s
      "i#{sub_instance_id}  #{@expression_id}"
    end

    #
    # Returns the workflow instance id without any subflow indices.
    # For example, if the wfid is "1234.0.1", this method will
    # return "1234".
    #
    def parent_workflow_instance_id

      FlowExpressionId.to_parent_wfid(workflow_instance_id)
    end

    alias :parent_wfid :parent_workflow_instance_id

    #
    # Returns '' if this expression id belongs to a top process,
    # returns something like ".0" or ".1.3" if this exp id belongs to
    # an expression in a subprocess.
    # (Only used in some unit tests for now)
    #
    def sub_instance_id

      i = workflow_instance_id.index('.')
      i ? workflow_instance_id[i..-1] : ''
    end

    #
    # If this flow expression id belongs to a sub instance, a call to
    # this method will return the last number of the sub instanceid.
    #
    # For example, in the case of the instance "20071114-dukikomino.1", "1"
    # will be returned. For "20071114-dukikomino.1.0", "0" will be returned.
    #
    # If the flow expression id doesn't belong to a sub instance, nil
    # will be returned.
    #
    def last_sub_instance_id

      i = workflow_instance_id.rindex('.')
      i ? workflow_instance_id[i+1..-1] : nil
    end

    #
    # Returns true if this flow expression id belongs to a process
    # which is not a subprocess.
    #
    def is_in_parent_process?

      (sub_instance_id == '')
    end

    #
    # Returns the last part of the expression_id. For example, if
    # the expression_id is "0.1.0.4", "4" will be returned.
    #
    # This method is used in "concurrence" when merging workitems coming
    # backing from the children expressions.
    #
    def child_id

      i = @expression_id.rindex(".")
      i ? @expression_id[i+1..-1] : @expression_id
    end

    #
    # This class method parses a string into a FlowExpressionId instance
    #
    def self.to_fei (string)

      fei = FlowExpressionId.new

      ss = string.split

      ss = ss[1..-1] if ss[0] == '('

      fei.owfe_version = ss[1]

      ssRawEngineId = ss[2].split('/')
      fei.engine_id = ssRawEngineId[0]
      #fei.initial_engine_id = ssRawEngineId[1]

      fei.workflow_definition_url = ss[3]
      fei.workflow_definition_name = ss[4]
      fei.workflow_definition_revision = ss[5]
      fei.workflow_instance_id = ss[6]
      fei.expression_name = ss[7]
      fei.expression_id = ss[8][0..-2]

      fei.expression_id = fei.expression_id[0..-2] \
        if fei.expression_id[-1, 1] == ')'

      fei
    end

    #
    # An alias for to_fei(string)
    #
    def self.from_s (string)

      to_fei(string)
    end

    #
    # If wfid is already a 'parent wfid' (no sub id), returns it. Else
    # returns the parent wfid (whatever is before the first ".").
    #
    def self.to_parent_wfid (wfid)

      wfid.split('.').first
    end

    #
    # custom yaml serialization

    yaml_as("tag:ruby.yaml.org,2002:#{self}")

    def to_yaml (opts={}) #:nodoc#
      YAML::quick_emit(self.object_id, opts) do |out|
        out.map(taguri) { |map| map.add('s', to_s) }
      end
    end

    def self.yaml_new (klass, tag, val) #:nodoc#
      begin
        FlowExpressionId.to_fei(val['s'])
      rescue Exception => e
        raise "failed to decode FlowExpressionId out of '#{s}', #{e}"
      end
    end
  end

end

