#
#--
# Copyright (c) 2007-2009, Tomaso Tosolini, John Mettraux OpenWFE.org
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
# "made in Italy"
#
# Tomaso Tosolini
# John Mettraux
#

#require_gem 'activerecord'
gem 'activerecord'; require 'active_record'

require 'openwfe/service'
require 'openwfe/rudefinitions'
require 'openwfe/expool/expstorage'
require 'openwfe/expool/threaded_expstorage'


module OpenWFE::Extras

  #
  # A migration for creating/dropping the "expressions" table.
  # 'expressions' are atomic pieces of running process instances.
  #
  class ExpressionTables < ActiveRecord::Migration

    def self.up

      create_table :expressions do |t|

        t.column :fei, :string, :null => false
        t.column :wfid, :string, :null => false
        t.column :expid, :string, :null => false
        #t.column :wfname, :string, :null => false
        t.column :exp_class, :string, :null => false

        #t.column :svalue, :text, :null => false
        t.column :svalue, :text, :null => false, :limit => 1024 * 1024
          #
          # 'value' could be reserved, using 'svalue' instead
          #
          # :limit patch by Maarten Oelering (a greater value
          # could be required in some cases)
      end
      add_index :expressions, :fei
      add_index :expressions, :wfid
      add_index :expressions, :expid
      #add_index :expressions, :wfname
      add_index :expressions, :exp_class
    end

    def self.down

      drop_table :expressions
    end
  end

  #
  # The ActiveRecord wrapper for an OpenWFEru FlowExpression instance.
  #
  class Expression < ActiveRecord::Base

    serialize :svalue
  end

  #
  # Storing OpenWFE flow expressions in a database.
  #
  class DbExpressionStorage

    include OpenWFE::ServiceMixin
    include OpenWFE::OwfeServiceLocator
    include OpenWFE::ExpressionStorageBase

    #
    # Constructor.
    #
    def initialize (service_name, application_context)

      require 'openwfe/storage/yaml_custom'
        # making sure this file has been required at this point
        # this yamlcustom thing prevents the whole OpenWFE ecosystem
        # to get serialized :)

      super()
      service_init(service_name, application_context)

      observe_expool
    end

    #
    # Stores an expression.
    #
    def []= (fei, flow_expression)

      #ldebug { "[]= storing #{fei.to_s}" }

      e = Expression.find_by_fei fei.to_s

      unless e
        e = Expression.new
        e.fei = fei.to_s
        e.wfid = fei.wfid
        e.expid = fei.expid
        #e.wfname = fei.wfname
      end

      e.exp_class = flow_expression.class.name
      e.svalue = flow_expression

      #p [ Thread.current.object_id,
      #    e.connection.instance_variable_get(:@connection) ]

      e.save!
    end

    #
    # Retrieves a flow expression.
    #
    def [] (fei)

      e = Expression.find_by_fei(fei.to_s)
      return nil unless e

      as_owfe_expression(e)
    end

    #
    # Returns true if there is a FlowExpression stored with the given id.
    #
    def has_key? (fei)

      (Expression.find_by_fei(fei.to_s) != nil)
    end

    #
    # Deletes a flow expression.
    #
    def delete (fei)

      Expression.delete_all([ 'fei = ?', fei.to_s ])
    end

    #
    # Returns the count of expressions currently stored.
    #
    def size

      Expression.count
    end

    alias :length :size

    #
    # Danger ! Will remove all the expressions in the database.
    #
    def purge

      Expression.delete_all
    end

    #
    # Gather expressions matching certain parameters.
    #
    def find_expressions (options={})

      conditions = determine_conditions(options)
        # note : this call modifies the options hash...

      #
      # maximize usage of SQL querying

      exps = Expression.find(:all, :conditions => conditions)

      #
      # do the rest of the filtering

      exps = exps.collect do |exp|
        as_owfe_expression(exp)
      end

      exps.find_all do |fexp|
        does_match?(options, fexp)
      end
    end

    #
    # Fetches the root of a process instance.
    #
    def fetch_root (wfid)

      params = {}

      params[:conditions] = [
        'wfid = ? AND exp_class = ?',
        wfid,
        OpenWFE::DefineExpression.to_s
      ]

      exps = Expression.find(:all, params)

      e = exps.sort { |fe1, fe2| fe1.fei.expid <=> fe2.fei.expid }[0]
        #
        # find the one with the smallest expid

      as_owfe_expression(e)
    end

    protected

      #
      # Grabs the options to build a conditions array for use by
      # find().
      #
      # Note : this method, modifies the options hash (it removes
      # the args it needs).
      #
      def determine_conditions (options)

        wfid = options.delete :wfid
        wfid_prefix = options.delete :wfid_prefix
        #parent_wfid = options.delete :parent_wfid

        query = []
        conditions = []

        if wfid
          query << 'wfid = ?'
          conditions << wfid
        elsif wfid_prefix
          query << 'wfid LIKE ?'
          conditions << "#{wfid_prefix}%"
        end

        add_class_conditions options, query, conditions

        conditions = conditions.flatten

        if conditions.size < 1
          nil
        else
          conditions.insert(0, query.join(' AND '))
        end
      end

      #
      # Used by determine_conditions().
      #
      def add_class_conditions (options, query, conditions)

        ic = options.delete :include_classes
        ic = Array(ic)

        ec = options.delete :exclude_classes
        ec = Array(ec)

        acc ic, query, conditions, 'OR'
        acc ec, query, conditions, 'AND'
      end

      def acc (classes, query, conditions, join)

        return if classes.size < 1

        classes = classes.collect do |kind|
          get_expression_map.get_expression_classes kind
        end
        classes = classes.flatten

        quer = []
        cond = []
        classes.each do |cl|

          quer << if join == 'AND'
            'exp_class != ?'
          else
            'exp_class = ?'
          end

          cond << cl.to_s
        end
        quer = quer.join(" #{join} ")

        query << "(#{quer})"
        conditions << cond
      end

      #
      # Extracts the OpenWFE FlowExpression instance from the
      # active record and makes sure its application_context is set.
      #
      def as_owfe_expression (record)

        return nil unless record

        fe = record.svalue
        fe.application_context = @application_context
        fe
      end
  end

  #
  # A DbExpressionStorage that does less work, for more performance,
  # thanks to the ThreadedStorageMixin.
  #
  class ThreadedDbExpressionStorage < DbExpressionStorage
    include OpenWFE::ThreadedStorageMixin

    def initialize (service_name, application_context)

      super

      start_queue
        #
        # which sets @thread_id
    end
  end
end

