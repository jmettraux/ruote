#--
# Copyright (c) 2007-2009, John Mettraux, Tomaso Tosolini OpenWFE.org
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
# Made in Japan and Italy.
#++


require 'openwfe/workitem'
require 'openwfe/flowexpressionid'
require 'openwfe/engine/engine'
require 'openwfe/participants/participant'
require 'openwfe/extras/singlecon'


module OpenWFE::Extras

  class ArWorkitemTables < ActiveRecord::Migration

    def self.up

      create_table :ar_workitems do |t|

        t.column :fei, :string
        t.column :wfid, :string
        t.column :expid, :string
        t.column :wfname, :string
        t.column :wfrevision, :string

        t.column :participant_name, :string
        t.column :store_name, :string

        t.column :dispatch_time, :timestamp
        t.column :last_modified, :timestamp

        t.column :wi_fields, :text

        t.column :activity, :string
        t.column :keywords, :text
      end

      add_index :ar_workitems, :fei, :unique => true
        # with sqlite3, comment out this :unique => true on :fei :(

      add_index :ar_workitems, :wfid
      add_index :ar_workitems, :expid
      add_index :ar_workitems, :wfname
      add_index :ar_workitems, :wfrevision
      add_index :ar_workitems, :participant_name
      add_index :ar_workitems, :store_name
    end

    def self.down

      drop_table :ar_workitems
    end
  end

  class ArWorkitem < ActiveRecord::Base
    include SingleConnectionMixin

    #
    # Returns the flow expression id of this work (its unique OpenWFEru (Ruote)
    # identifier) as a FlowExpressionId instance.
    # (within the Workitem it's just stored as a String).
    #
    def full_fei

      @full_fei ||= OpenWFE::FlowExpressionId.from_s(fei)
    end

    #
    # Making sure last_modified is set to Time.now before each save.
    #
    def before_save

      touch
    end

    def self.from_owfe_workitem (wi, store_name=nil)

      arwi = ArWorkitem.new
      arwi.fei = wi.fei.to_s
      arwi.wfid = wi.fei.wfid
      arwi.expid = wi.fei.expid
      arwi.wfname = wi.fei.workflow_definition_name
      arwi.wfrevision = wi.fei.workflow_definition_revision

      arwi.participant_name = wi.participant_name
      arwi.store_name = store_name

      arwi.dispatch_time = wi.dispatch_time
      arwi.last_modified = nil

      arwi.wi_fields = YAML.dump(wi.fields)
        # using YAML as it's more future proof

      arwi.keywords = flatten_keywords(wi.fields, wi.participant_name)

      #arwi.save! # making sure to throw an exception in case of trouble
      arwi.save_without_transactions!

      arwi
    end

    #
    # The default implementation fetches the value for the 'activity' in
    # the hash field named 'params'.
    #
    def extract_activity (wi)

      wi.fields['params']['activity']
    end

    #
    # Turns the 'active' Workitem into a ruote InFlowWorkItem.
    #
    def to_owfe_workitem

      wi = OpenWFE::InFlowWorkItem.new

      wi.fei = full_fei
      wi.participant_name = participant_name
      wi.fields = YAML.load(self.wi_fields)

      wi.dispatch_time = dispatch_time
      wi.last_modified = last_modified

      wi
    end

    alias :as_owfe_workitem :to_owfe_workitem

    def replace_fields (fields)

      self.wi_fields = YAML.dump(fields)

      self.keywords = self.class.flatten_keywords(fields, self.participant_name)

      #self.save!
      self.save_without_transactions!
    end

    def field_hash

      YAML.load(self.wi_fields)
    end

    def field (k)

      field_hash[k]
    end

    #
    # Simply sets the 'last_modified' field to now.
    # (Doesn't save the workitem though).
    #
    def touch

      self.last_modified = Time.now
    end

    #
    # Returns all the workitems belonging to the stores listed
    # in the parameter storename_list.
    # The result is a Hash whose keys are the store names and whose
    # values are list of workitems.
    #
    def self.find_in_stores (storename_list)

      workitems = find_all_by_store_name(storename_list)
      workitems.inject({}) { |h, wi| (h[wi.store_name] ||= []) << wi }
    end

    #
    # Not really about 'just launched', but rather about finding the first
    # workitem for a given process instance (wfid) and a participant.
    # It deserves its own method because the workitem could be in a
    # subprocess, thus escaping the vanilla find_by_wfid_and_participant()
    #
    def self.find_just_launched (wfid, participant_name)

      find(
        :first,
        :conditions => [
          'wfid LIKE ? AND participant_name = ?',
          "#{wfid}%",
          participant_name ])
    end

    #
    # a very naive search functionality
    #
    def self.search (query, store_names)

      query = query.split(' ').first

      i = query.index(':')

      query = if i == query.length - 1
        "%|#{query}%"
      elsif i != nil and i != 0
        "%|#{query}|%"
      else
        "%#{query}|%"
      end

      conditions = [ 'keywords LIKE ?', query ]

      if store_names and not (store_names.empty?)
        conditions[0] = "#{conditions[0]} AND store_name IN (?)"
        conditions << store_names
      end

      #p conditions

      find(:all, :conditions => conditions)
    end

    protected

    def self.flatten_keywords (h, participant_name)

      h = h.merge('participant' => participant_name) if participant_name

      fk(h).gsub(/\|+/, '|')
    end

    def self.fk (o)

      if o.is_a?(Hash)
        "|#{o.collect { |k, v| "#{fk(k)}:#{fk(v)}" }.join('|')}|"
      elsif o.is_a?(Array)
        "|#{o.collect { |e| fk(e) }.join('|')}|"
      else
        o.to_s.gsub('|', '').gsub(':', '')
      end
    end
  end

  class ArParticipant
    include OpenWFE::LocalParticipant

    attr_reader :store_name

    def initialize (opts={})

      super()

      @store_name = opts[:store_name]
    end

    #--
    ## Forces ruote to not spawn a thread when dispatching to this participant.
    ##
    #def do_not_thread
    #  true
    #end
    #++

    def consume (workitem)

      ArWorkitem.from_owfe_workitem(workitem, @store_name)
    end

    def cancel (cancelitem)

      ArWorkitem.destroy_all([ 'fei = ?', cancelitem.fei.to_s ])
    end
  end

end

