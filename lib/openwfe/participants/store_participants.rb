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

    # optional field (only used by the old rest interface for now)
    #
    attr_accessor :store_name

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

    # Called by the participant expression when this participant is
    # 'cancelled' within a flow. The workitem then gets removed.
    #
    def cancel (cancelitem)

      ldebug { "cancel() removing workitem  #{cancelitem.flow_expression_id}" }

      delete(cancelitem.fei)
    end

    # The workitem is to be stored again within the store participant,
    # it will probably be reused later. Don't send back to engine yet.
    #
    def save (workitem)

      raise "Workitem not found in #{self.class}, cannot save." \
        unless self.has_key? workitem.flow_expression_id

      self[workitem.flow_expression_id] = workitem
    end

    # The workflow client is done with the workitem, send it back to
    # the engine and make sure it's not in the store participant anymore.
    #
    def forward (workitem)

      raise "Workitem not found in #{self.class}, cannot forward." \
        unless self.has_key?(workitem.flow_expression_id)

      delete(workitem.fei)

      reply_to_engine(workitem)
    end

    # 'proceed' is just an alias for 'forward'
    #
    alias :proceed :forward

    # deletes the workitems corresponding to the given flow expression id (fei).
    #
    def delete (fei)

      super(fei)
    end

    # A convenience method for delegating a workitem to another
    # store participant.
    #
    def delegate (wi_or_fei, other_store_participant)

      wi = delete(wi_or_fei)
      other_store_participant.push(wi)
    end

    # Returns all the workitems for a given workflow instance id.
    # If no workflow_instance_id is given, all the workitems will be
    # returned.
    #
    def list_workitems (workflow_instance_id=nil)

      workflow_instance_id ?
        self.values.select { |wi| wi.fei.parent_wfid == workflow_instance_id } :
        self.values
    end

    # Returns the first workitem at hand.
    # As a StoreParticipant is usually implemented with a hash, two
    # consecutive calls to this method might not return the same workitem
    # (except if the store is empty or contains 1! workitem).
    #
    def first_workitem

      self.values.first
    end

    # Joins this participant, ie wait until a workitem arrives in it
    #
    def join (force_wait=false)

      return if self.size > 0 && (not force_wait)

      (@waiting_threads ||= []) << Thread.current
      Thread.stop
    end

    protected

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
  #   require 'openwfe/participants/store_participants'
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
  # Stores workitems in the filesystem.
  #
  # Don't use this class directly, instead use YamlParticipant or another
  # of the subclasses.
  #
  class FsParticipant

    include Enumerable
    include StoreParticipantMixin

    attr_reader :path
    attr_reader :dirname
    attr_reader :fullpath

    # Instantiates the participant.
    #
    # There are two options, :path and :fullpath. The dir where the workitems
    # are placed is determined by :
    #
    #   {ruote_work_dir}/{:path}/{participant_name}/
    #
    # if :fullpath is set, it simply becomes
    #
    #   {:fullpath}/
    #
    def initialize (options={})

      self.application_context = options[:application_context]

      @path = options[:path] || 'participants'
      @dirname = OpenWFE::ensure_for_filename(options[:regex].to_s)

      @fullpath =
        options[:fullpath] || File.join(get_work_directory, @path, @dirname)

      FileUtils.mkdir_p(@fullpath)
    end

    def [] (fei)

      load_workitem(filename_for(fei))
    end

    def []= (fei, workitem)

      File.open(filename_for(fei), 'w') do |f|
        f.write(encode_workitem(workitem))
      end
    end

    def delete (fei)

      begin
        FileUtils.rm_f(filename_for(fei))
      rescue Exception => e
        # don't care
      end
    end

    def values

      Dir.entries(@fullpath).inject([]) do |workitems, path|
        workitem = load_workitem(File.join(@fullpath, path))
        workitems << workitem if workitem
        workitems
      end
    end

    def purge

      FileUtils.rm_rf(@fullpath)
    end

    def size

      paths.size
    end

    def each (&block)

      return unless block

      values.each do |workitem|
        block.call(workitem.fei, workitem)
      end
    end

    protected

    def paths

      Dir.entries(@fullpath).inject([]) do |paths, path|
        paths << path if is_workitem_path?(File.join(@fullpath, path))
        paths
      end
    end
  end

  #
  # A store participant class that places workitems in the work directory
  # (generally under /work/participants/{participant_name}/) as YAML files.
  #
  #   require 'openwfe/participants/store_participants'
  #
  #   engine.register_participant :accounting, YamlParticipant
  #     # will store workitems under work/participants/accounting/
  #
  #   engine.register_participant :accounting, YamlParticipant, :path => 'parts'
  #     # will store workitems under work/parts/accounting/
  #
  #   engine.register_participant :accounting, YamlParticipant, :fullpath => '/tmp/workitems/acct/'
  #     # will store workitems under /tmp/workitems/acct/
  #
  class YamlParticipant < FsParticipant

    protected

    def is_workitem_path? (path)

      path.match(/\.yaml$/)
    end

    def encode_workitem (workitem)

      YAML.dump(workitem)
    end

    def load_workitem (path)

      return nil unless is_workitem_path?(path)
      YAML.load_file(path)
    end

    def has_key? (fei)

      File.exist?(filename_for(fei))
    end

    def filename_for (fei)

      fn = [
        fei.workflow_instance_id, '__',
        fei.workflow_definition_name, '_',
        fei.workflow_definition_revision, '__',
        fei.expression_id, '.yaml'
      ].join

      File.join(@fullpath, fn)
    end
  end
end

