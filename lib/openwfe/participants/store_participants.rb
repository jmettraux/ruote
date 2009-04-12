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


require 'openwfe/utils'
require 'openwfe/omixins'
require 'openwfe/participants/yaml_filestorage'
require 'openwfe/participants/participant'


module OpenWFE

  #
  # A mixin gathering the methods a workitem store participant needs.
  #
  # Two kinds of methods are involved here, the ones used by the engine
  # (its participant map) and the ones used by 'workflow clients'.
  # Thus consume() and cancel() are triggered by the engine, and
  # save() and forward() are at the disposal of 'workflow clients'.
  #
  # A 'workflow client' is supposed to use methods similar to hash methods
  # to retrieve workitems, like in
  #
  #   storeparticipant.each do |fei, workitem|
  #     puts "workitem : #{fei.to_s}"
  #     do_some_work(workitem)
  #   end
  #
  #
  module StoreParticipantMixin

    include LocalParticipant
    include FeiMixin

    #
    # optional field (only used by the old rest interface for now)
    #
    attr_accessor :store_name

    #
    # Called by the engine (the participant expression) when handing
    # out a workitem (to this participant).
    #
    # This method can also be used when delegating a workitem from
    # one store participant to the other.
    #
    def consume (workitem)

      self[workitem.flow_expression_id] = workitem

      notify_waiting_threads
    end
    alias :push :consume

    #
    # Called by the participant expression when this participant is
    # 'cancelled' within a flow. The workitem then gets removed.
    #
    def cancel (cancelitem)

      ldebug { "cancel() removing workitem  #{cancelitem.flow_expression_id}" }

      delete(cancelitem.flow_expression_id)
    end

    #
    # The workitem is to be stored again within the store participant,
    # it will probably be reused later. Don't send back to engine yet.
    #
    def save (workitem)

      raise "Workitem not found in #{self.class}, cannot save." \
        unless self.has_key? workitem.flow_expression_id

      self[workitem.flow_expression_id] = workitem
    end

    #
    # The workflow client is done with the workitem, send it back to
    # the engine and make sure it's not in the store participant anymore.
    #
    def forward (workitem)

      raise "Workitem not found in #{self.class}, cannot forward." \
        unless self.has_key?(workitem.flow_expression_id)

      delete(workitem)

      reply_to_engine(workitem)
    end

    #
    # 'proceed' is just an alias for 'forward'
    #
    alias :proceed :forward

    #
    # This delete() method accepts a workitem or simply its FlowExpressionId
    # identifier.
    #
    def delete (wi_or_fei)

      super(extract_fei(wi_or_fei))
    end

    #
    # A convenience method for delegating a workitem to another
    # store participant.
    #
    def delegate (wi_or_fei, other_store_participant)

      wi = delete(wi_or_fei)
      other_store_participant.push(wi)
    end

    #
    # Returns all the workitems for a given workflow instance id.
    # If no workflow_instance_id is given, all the workitems will be
    # returned.
    #
    def list_workitems (workflow_instance_id=nil)

      workflow_instance_id ?
        self.values.select { |wi| wi.fei.parent_wfid == workflow_instance_id } :
        self.values
    end

    #
    # Returns the first workitem at hand.
    # As a StoreParticipant is usually implemented with a hash, two
    # consecutive calls to this method might not return the same workitem
    # (except if the store is empty or contains 1! workitem).
    #
    def first_workitem

      self.values.first
    end

    #
    # Joins this participant, ie wait until a workitem arrives in it
    #
    def join (force_wait=false)
      return if self.size > 0 && (not force_wait)
      (@waiting_threads ||= []) << Thread.current
      Thread.stop
    end

    protected

    #
    # This method is called each time a workitem comes in. Waiting threads
    # get woken up.
    #
    def notify_waiting_threads
      return unless @waiting_threads
      @waiting_threads.each { |t| t.wakeup }
      @waiting_threads.clear
    end
  end

  #
  # The simplest workitem store possible, gathers the workitem in a
  # hash (this class is an extension of Hash).
  #
  # Some examples :
  #
  #   engine.register_participant(:alice, OpenWFE::HashParticipant)
  #   engine.register_participant("bob", OpenWFE::HashParticipant)
  #
  #   hp = engine.register_participant(:charly, OpenWFE::HashParticipant)
  #   #...
  #   puts "there are currently #{hp.size} workitems for Charly"
  #
  #   hp = OpenWFE::HashParticipant.new
  #   engine.register_participant("debbie", hp)
  #
  class HashParticipant < Hash
    include StoreParticipantMixin

    # that's all...
  end

  #
  # Implementation of a store participant stores the workitems in
  # yaml file in a dedicated directory.
  #
  # It's quite easy to register a YamlParticipant :
  #
  #   yp = engine.register_participant(:alex, YamlParticipant)
  #
  #   puts yp.dirname
  #
  # should yield "./work/participants/alex/" (if the key :work_directory
  # in engine.application_context is unset)
  #
  class YamlParticipant < YamlFileStorage
    include StoreParticipantMixin

    attr_accessor :dirname

    #
    # The constructor for YamlParticipant awaits a dirname and an
    # application_context.
    # The dirname should be a simple name acceptable as a filename.
    #
    def initialize (dirname, application_context)

      @dirname = OpenWFE::ensure_for_filename(dirname.to_s)

      service_name = self.class.name + '__' + @dirname

      path = '/participants/' + @dirname

      super(service_name, application_context, path)
    end

    protected

    def compute_file_path (fei)
      [
        @basepath,
        fei.workflow_instance_id, '__',
        fei.workflow_definition_name, '_',
        fei.workflow_definition_revision, '__',
        fei.expression_id, '.yaml'
      ].join
    end
  end
end
