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


require 'base64'

require 'dm-core'

require 'openwfe/service'
require 'openwfe/rudefinitions'
require 'openwfe/expool/expstorage'


module OpenWFE::Extras

  #
  # The datamapper resource class for Ruote expressions.
  #
  class DmExpression
    include DataMapper::Resource

    property :fei, String, :key => true
    property :wfid, String, :index => :wfid
    property :expid, String, :index => :expid
    property :expclass, String, :index => :expclass
    property :svalue, Text

    def svalue= (fexp)

      attribute_set(:svalue, Base64.encode64(Marshal.dump(fexp)))
    end

    def as_owfe_expression (application_context)

      fe = Marshal.load(Base64.decode64(self.svalue))
      fe.application_context = application_context
      fe
    end

    def self.storage_name (repository_name = default_repository_name)
      'dm_expressions'
    end
  end

  #
  # Storing Ruote's flow expressions via DataMapper.
  #
  class DmExpressionStorage

    include OpenWFE::ServiceMixin
    include OpenWFE::OwfeServiceLocator
    include OpenWFE::ExpressionStorageBase

    attr_accessor :dm_repository

    #
    # Instantiates a DmExpressionStorage service. (Where dm stands for
    # Data Mapper).
    #
    def initialize (service_name, application_context)

      super()
      service_init(service_name, application_context)

      @dm_repository =
        application_context[:expstorage_dm_repository] || :default

      DataMapper.repository(@dm_repository) {
        DmExpression.auto_upgrade!
      }

      observe_expool
    end

    #
    # Stores an expression.
    #
    def []= (fei, flow_expression)

      DataMapper.repository(@dm_repository) {

        e = find(fei) || DmExpression.new

        e.fei = fei.as_string_key
        e.wfid = fei.wfid
        e.expid = fei.expid
        e.expclass = flow_expression.class.name
        e.svalue = flow_expression

        e.save
      }
    end

    #
    # Retrieves a flow expression.
    #
    def [] (fei)

      if e = find(fei)
        e.as_owfe_expression(self.application_context)
      else
        nil
      end
    end

    #
    # Finds the DmExpression instance with the given fei (FlowExpressionId)
    #
    def find (fei)

      DataMapper.repository(@dm_repository) {
        DmExpression.first(:fei => fei.as_string_key)
      }
    end

    #
    # Returns true if there is a FlowExpression stored with the given id.
    #
    def has_key? (fei)

      (self[fei] != nil)
    end

    #
    # Deletes a flow expression.
    #
    def delete (fei)

      e = find(fei)
      e.destroy if e
    end

    #
    # Returns the count of expressions currently stored.
    #
    def size

      DataMapper.repository(@dm_repository) { DmExpression.count }
    end

    alias :length :size

    #
    # Danger ! Will remove all the expressions in the database.
    #
    def purge

      DataMapper.repository(@dm_repository) {

        DmExpression.all.each { |de| de.destroy }
          #
          # TODO : find simpler way to do that
      }
    end

    #
    # Gather expressions matching certain parameters.
    #
    def find_expressions (options={})

      #conditions = determine_conditions(options)
        # note : this call modifies the options hash...

      conditions = {}

      #
      # maximize usage of SQL querying

      exps = DataMapper.repository(@dm_repository) {
        DmExpression.all(conditions)
      }

      #
      # do the rest of the filtering

      exps.inject([]) { |a, de|
        fe = de.as_owfe_expression(application_context)
        a << fe if does_match?(options, fe)
        a
      }
    end

    #
    # Fetches the root of a process instance.
    #
    def fetch_root (wfid)

      e = DataMapper.repository(@dm_repository) {

        DmExpression.first(
          :wfid => wfid,
          :expclass => OpenWFE::DefineExpression.to_s,
          :order => [ :expid.asc ])
      }

      e ? e.as_owfe_expression(self.application_context) : nil
    end

    #
    # Used only by work/pooltool.ru for storage migrations.
    #
    def each

      return unless block_given?

      exps = DataMapper.repository(@dm_repository) { DmExpression.all }

      exps.each do |de|
        fe = de.as_owfe_expression(self.application_context)
        yield(fe.fei, fe)
      end
    end

    #
    # Closes the underlying database... Does nothing in this implementation.
    #
    def close

      # nothing to do here.
    end

#    protected
#
#    #
#    # Grabs the options to build a conditions array for use by
#    # find().
#    #
#    # Note : this method, modifies the options hash (it removes
#    # the args it needs).
#    #
#    def determine_conditions (options)
#
#      wfid = options.delete :wfid
#      wfid_prefix = options.delete :wfid_prefix
#      #parent_wfid = options.delete :parent_wfid
#
#      query = []
#      conditions = []
#
#      if wfid
#        query << 'wfid = ?'
#        conditions << wfid
#      elsif wfid_prefix
#        query << 'wfid LIKE ?'
#        conditions << "#{wfid_prefix}%"
#      end
#
#      add_class_conditions(options, query, conditions)
#
#      conditions = conditions.flatten
#
#      if conditions.size < 1
#        nil
#      else
#        conditions.insert(0, query.join(' AND '))
#      end
#    end
#
#    #
#    # Used by determine_conditions().
#    #
#    def add_class_conditions (options, query, conditions)
#
#      ic = options.delete :include_classes
#      ic = Array(ic)
#
#      ec = options.delete :exclude_classes
#      ec = Array(ec)
#
#      acc ic, query, conditions, 'OR'
#      acc ec, query, conditions, 'AND'
#    end
#
#    def acc (classes, query, conditions, join)
#
#      return if classes.size < 1
#
#      classes = classes.collect do |kind|
#        get_expression_map.get_expression_classes kind
#      end
#      classes = classes.flatten
#
#      quer = []
#      cond = []
#      classes.each do |cl|
#
#        quer << if join == 'AND'
#          'exp_class != ?'
#        else
#          'exp_class = ?'
#        end
#
#        cond << cl.to_s
#      end
#      quer = quer.join(" #{join} ")
#
#      query << "(#{quer})"
#      conditions << cond
#    end

  end
end

