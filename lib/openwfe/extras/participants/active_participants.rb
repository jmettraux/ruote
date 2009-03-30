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
# Made in Italy.
#++


#require_gem 'activerecord'
#gem 'activerecord'; require 'active_record'
require 'active_record'


require 'openwfe/workitem'
require 'openwfe/flowexpressionid'
require 'openwfe/engine/engine'
require 'openwfe/participants/participant'


module OpenWFE
module Extras

  #
  # DEPRECATED !! use openwfe/extras/participants/ar_participants instead
  #
  # The migration for ActiveParticipant and associated classes.
  #
  # There are two tables 'workitems' and 'fields'. As its name implies,
  # the latter table stores the fields (also called attributes in OpenWFE
  # speak) of the workitems.
  #
  # See Workitem and Field for more details.
  #
  # For centralization purposes, the migration and the model are located
  # in the same source file. It should be quite easy for the Rails hackers
  # among you to sort that out for a Rails based usage.
  #
  class WorkitemTables < ActiveRecord::Migration

    def self.up

      create_table :workitems do |t|
        t.column :fei, :string
        t.column :wfid, :string
        t.column :expid, :string
        t.column :wf_name, :string
        t.column :wf_revision, :string
        t.column :participant_name, :string
        t.column :store_name, :string
        t.column :dispatch_time, :timestamp
        t.column :last_modified, :timestamp

        t.column :yattributes, :text
          # when using compact_workitems, attributes are stored here
      end
      add_index :workitems, :fei, :unique => true
        # with sqlite3, comment out this :unique => true on :fei :(
      add_index :workitems, :wfid
      add_index :workitems, :expid
      add_index :workitems, :wf_name
      add_index :workitems, :wf_revision
      add_index :workitems, :participant_name
      add_index :workitems, :store_name

      create_table :fields do |t|
        t.column :fkey, :string, :null => false
        t.column :vclass, :string, :null => false
        t.column :svalue, :string
        t.column :yvalue, :text
        t.column :workitem_id, :integer, :null => false
      end
      #add_index :fields, [ :workitem_id, :fkey ], :unique => true
      #add_index :fields, :workitem_id
      add_index :fields, :fkey
      add_index :fields, :vclass
      add_index :fields, :svalue
    end

    def self.down

      drop_table :workitems
      drop_table :fields
    end
  end

  #
  # Reopening InFlowWorkItem to add a 'db_id' attribute.
  #
  class OpenWFE::InFlowWorkItem

    attr_accessor :db_id
      # deprecated !
  end

  #
  # The ActiveRecord version of an OpenWFEru workitem (InFlowWorkItem).
  #
  # One can very easily build a worklist based on a participant name via :
  #
  #   wl = OpenWFE::Extras::Workitem.find_all_by_participant_name("toto")
  #   puts "found #{wl.size} workitems for participant 'toto'"
  #
  # These workitems are not OpenWFEru workitems directly. But the conversion
  # is pretty easy.
  # Note that you probaly won't need to do the conversion by yourself,
  # except for certain advanced scenarii.
  #
  #   awi = OpenWFE::Extras::Workitem.find_by_participant_name("toto")
  #     #
  #     # returns the first workitem in the database whose participant
  #     # name is 'toto'.
  #
  #   owi = awi.as_owfe_workitem
  #   #owi = awi.to_owfe_workitem
  #     #
  #     # Now we have a copy of the reference as a OpenWFEru
  #     # InFlowWorkItem instance.
  #
  #   awi = OpenWFE::Extras::Workitem.from_owfe_workitem(owi)
  #     #
  #     # turns an OpenWFEru InFlowWorkItem instance into an
  #     # 'active workitem'.
  #
  class Workitem < ActiveRecord::Base

    def connection
      ActiveRecord::Base.verify_active_connections!
      super
    end

    has_many(
      :fields,
      :dependent => :delete_all,
      :class_name => 'OpenWFE::Extras::Field')

    serialize :yattributes

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

    #
    # Generates a (new) Workitem from an OpenWFEru InFlowWorkItem instance.
    #
    # This is a 'static' method :
    #
    #   awi = OpenWFE::Extras::Workitem.from_owfe_workitem(wi)
    #
    # (This method saves the 'ActiveWorkitem').
    #
    def Workitem.from_owfe_workitem (wi, store_name=nil)

      i = Workitem.new
      i.fei = wi.fei.to_s
      i.wfid = wi.fei.wfid
      i.expid = wi.fei.expid
      i.wf_name = wi.fei.workflow_definition_name
      i.wf_revision = wi.fei.workflow_definition_revision
      i.participant_name = wi.participant_name
      i.dispatch_time = wi.dispatch_time
      i.last_modified = nil

      i.store_name = store_name

      if wi.attributes['compact_workitems']

        wi.attributes.delete('compact_workitems')
        i.yattributes = wi.attributes

      else

        i.yattributes = nil
        wi.attributes.each { |k, v| i.fields << Field.new_field(k, v) }
      end

      i.save!
        # making sure to throw an exception in case of trouble

      i
    end

    #
    # Turns the 'active' Workitem into a ruote InFlowWorkItem.
    #
    def to_owfe_workitem (options={})

      wi = OpenWFE::InFlowWorkItem.new

      wi.fei = full_fei
      wi.participant_name = participant_name
      wi.attributes = fields_hash

      wi.dispatch_time = dispatch_time
      wi.last_modified = last_modified

      wi.db_id = self.id

      wi
    end

    alias :as_owfe_workitem :to_owfe_workitem

    #
    # Returns a hash version of the 'fields' of this workitem.
    #
    # (Each time this method is called, it returns a new hash).
    #
    def field_hash

      self.yattributes || fields.inject({}) { |r, f| r[f.fkey] = f.value; r }
    end

    alias :fields_hash :field_hash

    #
    # Replaces the current fields of this workitem with the given hash.
    #
    # This method modifies the content of the db.
    #
    def replace_fields (fhash)

      if self.yattributes

        #self.yattributes = fhash

      else

        fields.delete_all
        fhash.each { |k, v| fields << Field.new_field(k, v) }
      end

      #f = Field.new_field("___map_type", "smap")
        #
        # an old trick for backward compatibility with OpenWFEja

      save!
        # making sure to throw an exception in case of trouble
    end

    #
    # Returns the Field instance with the given key. This method accept
    # symbols as well as strings as its parameter.
    #
    #   wi.field("customer_name")
    #   wi.field :customer_name
    #
    def field (key)

      return self.yattributes[key.to_s] if self.yattributes

      fields.find_by_fkey(key.to_s)
    end

    #
    # A shortcut method, replies to the workflow engine and removes self
    # from the database.
    # Handy for people who don't want to play with an ActiveParticipant
    # instance when just consuming workitems (that an active participant
    # pushed in the database).
    #
    def reply (engine)

      engine.reply(self.as_owfe_workitem)
      self.destroy
    end

    alias :forward :reply
    alias :proceed :reply

    #
    # Simply sets the 'last_modified' field to now.
    # (Doesn't save the workitem though).
    #
    def touch

      self.last_modified = Time.now
    end

    #
    # Opening engine to update its reply method to accept these
    # active record workitems.
    #
    class OpenWFE::Engine

      alias :oldreply :reply

      def reply (workitem)

        if workitem.is_a?(Workitem)

          workitem.destroy
          oldreply(workitem.as_owfe_workitem)
        else

          oldreply(workitem)
        end
      end

      alias :forward :reply
      alias :proceed :reply
    end

    #
    # Returns all the workitems belonging to the stores listed
    # in the parameter storename_list.
    # The result is a Hash whose keys are the store names and whose
    # values are list of workitems.
    #
    def self.find_in_stores (storename_list)

      workitems = find_all_by_store_name(storename_list)

      result = {}

      workitems.each do |wi|
        (result[wi.store_name] ||= []) << wi
      end

      result
    end

    #
    # Some kind of 'google search' among workitems
    #
    # == Note
    #
    # when this is used on compact_workitems, it will not be able to search
    # info within the fields, because they aren't used by this kind of
    # workitems. In this case the search will be limited to participant_name
    #
    def self.search (search_string, storename_list=nil)

      #t = OpenWFE::Timer.new

      storename_list = Array(storename_list) if storename_list

      # participant_name

      result = find(
        :all,
        :conditions => conditions(
          'participant_name', search_string, storename_list),
        :order => 'participant_name')
        # :limit => 10)

      ids = result.collect { |wi| wi.id }

      # search in fields

      fields = Field.search(search_string, storename_list)
      merge_search_results(ids, result, fields)

      #puts "... took #{t.duration} ms"

      # over.

      result
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
          "wfid LIKE ? AND participant_name = ?",
          "#{wfid}%",
          participant_name ])
    end

    protected

    #
    # builds the condition (the WHERE clause) for the
    # search.
    #
    def self.conditions (keyname, search_string, storename_list)

      cs = [ "#{keyname} LIKE ?", search_string ]

      if storename_list

        cs[0] = "#{cs[0]} AND workitems.store_name IN (?)"
        cs << storename_list
      end

      cs
    end

    def self.merge_search_results (ids, wis, new_wis)

      return if new_wis.size < 1

      new_wis.each do |wi|
        wi = wi.workitem if wi.kind_of?(Field)
        next if ids.include? wi.id
        ids << wi.id
        wis << wi
      end
    end
  end

  #
  # A workaround is in place for some classes when then have to get
  # serialized. The names of thoses classes are listed in this array.
  #
  SPECIAL_FIELD_CLASSES = %w{ Time Date DateTime TrueClass FalseClass }

  #
  # A Field (Attribute) of a Workitem.
  #
  class Field < ActiveRecord::Base

    def connection
      ActiveRecord::Base.verify_active_connections!
      super
    end

    belongs_to :workitem, :class_name => 'OpenWFE::Extras::Workitem'

    serialize :yvalue

    #
    # A quick method for doing
    #
    #   f = Field.new
    #   f.key = key
    #   f.value = value
    #
    # One can then quickly add fields to an [active] workitem via :
    #
    #   wi.fields << Field.new_field("toto", "b")
    #
    # This method does not save the new Field.
    #
    def self.new_field (key, value)

      Field.new(:fkey => key, :vclass => value.class.to_s, :value => value)
    end

    def value= (v)

      limit = connection.native_database_types[:string][:limit]

      if v.is_a?(String) and v.length <= limit

        self.svalue = v

      elsif SPECIAL_FIELD_CLASSES.include?(v.class.to_s)

        self.svalue = v.to_yaml

      else

        self.yvalue = v
      end
    end

    def value

      return YAML.load(self.svalue) \
        if SPECIAL_FIELD_CLASSES.include?(self.vclass)

      self.svalue || self.yvalue
    end

    #
    # Will return all the fields that contain the given text.
    #
    # Looks in svalue and fkey. Looks as well in yvalue if it contains
    # a string.
    #
    # This method is used by Workitem.search()
    #
    def self.search (text, storename_list=nil)

      cs = build_search_conditions(text)

      if storename_list

        cs[0] = "(#{cs[0]}) AND workitems.store_name IN (?)"
        cs << storename_list
      end

      find(:all, :conditions => cs, :include => :workitem)
    end

    protected

    #
    # The search operates on the content of these columns
    #
    FIELDS_TO_SEARCH = %w{ svalue fkey yvalue }

    #
    # Builds the condition array for a pseudo text search
    #
    def self.build_search_conditions (text)

      has_percent = (text.index('%') != nil)

      conds = []

      conds << FIELDS_TO_SEARCH.collect { |key|

        count = has_percent ? 1 : 4

        s = ([ "#{key} LIKE ?" ] * count).join(" OR ")

        s = "(vclass = ? AND (#{s}))" if key == 'yvalue'

        s
      }.join(' OR ')

      FIELDS_TO_SEARCH.each do |key|

        conds << 'String' if key == 'yvalue'

        conds << text

        unless has_percent
          conds << "% #{text} %"
          conds << "% #{text}"
          conds << "#{text} %"
        end
      end

      conds
    end
  end


  #
  # A basic 'ActiveParticipant'.
  # A store participant whose store is a set of ActiveRecord tables.
  #
  # Sample usage :
  #
  #   class MyDefinition < OpenWFE::ProcessDefinition
  #     sequence do
  #       active0
  #       active1
  #     end
  #   end
  #
  #   def play_with_the_engine
  #
  #     engine = OpenWFE::Engine.new
  #
  #     engine.register_participant(
  #       :active0, OpenWFE::Extras::ActiveParticipant)
  #     engine.register_participant(
  #       :active1, OpenWFE::Extras::ActiveParticipant)
  #
  #     li = OpenWFE::LaunchItem.new(MyDefinition)
  #     li.customer_name = 'toto'
  #     engine.launch li
  #
  #     sleep 0.500
  #       # give some slack to the engine, it's asynchronous after all
  #
  #     wi = OpenWFE::Extras::Workitem.find_by_participant_name("active0")
  #
  #     # ...
  #  end
  #
  # == Compact workitems
  #
  # It is possible to save all the workitem data into a single table,
  # the workitems table, without
  # splitting info between workitems and fields tables.
  #
  # You can configure the "compact_workitems" behavior by adding to the
  # previous lines:
  #
  #   active0 = engine.register_participant(
  #     :active0, OpenWFE::Extras::ActiveParticipant)
  #
  #   active0.compact_workitems = true
  #
  # This behaviour is determined participant per participant, it's ok to
  # have a participant instance that compacts will there is another that
  # doesn't compact.
  #
  class ActiveParticipant
    include OpenWFE::LocalParticipant

    #
    # when compact_workitems is set to true, the attributes of a workitem
    # are stored in the yattributes column (they are not expanded into
    # the Fields table).
    # By default, workitem attributes are expanded.
    #
    attr :compact_workitems, true

    #
    # Forces ruote to not spawn a thread when dispatching to this participant.
    #
    def do_not_thread
      true
    end

    #
    # This is the method called by the OpenWFEru engine to hand a
    # workitem to this participant.
    #
    def consume (workitem)

      workitem.attributes['compact_workitems'] = true if compact_workitems

      Workitem.from_owfe_workitem workitem
        # does the 'saving to db'
    end

    #
    # Called by the engine when the whole process instance (or just the
    # segment of it that sports this participant) is cancelled.
    # Will removed the workitem with the same fei as the cancelitem
    # from the database.
    #
    # No expression will be raised if there is no corresponding workitem.
    #
    def cancel (cancelitem)

      Workitem.destroy_all([ 'fei = ?', cancelitem.fei.to_s ])
        # note that delete_all was not removing workitem fields
        # probably my fault (bad :has_many setting)
    end

    #
    # When the activity/work/operation whatever is over and the flow
    # should resume, this is the method to use to hand back the [modified]
    # workitem to the [local] engine.
    #
    def reply_to_engine (workitem)

      super(workitem.as_owfe_workitem)
        #
        # replies to the workflow engine

      workitem.destroy
        #
        # removes the workitem from the database
    end
  end

  #
  # An extension of ActiveParticipant. It has a 'store_name' and it
  # makes sure to flag every workitem it 'consumes' with that name
  # (in its 'store_name' column/field).
  #
  # This is the participant used mainly in 'densha' for human users.
  #
  class ActiveStoreParticipant < ActiveParticipant
    include Enumerable

    def initialize (store_name)

      super()
      @store_name = store_name
    end

    #
    # This is the method called by the OpenWFEru engine to hand a
    # workitem to this participant.
    #
    def consume (workitem)

      workitem.attributes['compact_workitems'] = true if compact_workitems

      Workitem.from_owfe_workitem(workitem, @store_name)
    end

    #
    # Iterates over the workitems currently in this store.
    #
    def each (&block)

      return unless block

      wis = Workitem.find_by_store_name(@store_name)

      wis.each { |wi| block.call(wi) }
    end
  end

end
end

