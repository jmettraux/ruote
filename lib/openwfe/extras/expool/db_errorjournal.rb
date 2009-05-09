#--
# Copyright (c) 2007-2009, Tomaso Tosolini, John Mettraux, OpenWFE.org
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


require 'openwfe/omixins'
require 'openwfe/expool/errorjournal'
require 'openwfe/extras/singlecon'


module OpenWFE::Extras

  #
  # A migration for creating/dropping the "process errors" table, the
  # content of this table makes up for an error journal.
  #
  # There is one record per process error, the log journal can be
  # easily rebuilt by doing find_all_by_wfid().
  #
  class ProcessErrorTables < ActiveRecord::Migration

    def self.up

      create_table :process_errors do |t|

        t.column :created_at, :timestamp
        t.column :wfid, :string, :null => false
        t.column :expid, :string, :null => false

        t.column :svalue, :text, :null => false
          # 'value' could be reserved, using 'svalue' instead
          # It stands for 'serialized value'.
      end
      add_index :process_errors, :created_at
      add_index :process_errors, :wfid
      add_index :process_errors, :expid
    end

    def self.down

      drop_table :process_errors
    end
  end

  #
  # The active record for process errors. Not much to say.
  #
  class ProcessError < ActiveRecord::Base
    include SingleConnectionMixin

    #serialize :svalue, OpenWFE::ProcessError
    serialize :svalue

    # Returns the OpenWFE process error, as serialized
    # (but takes care of setting its db_id)
    #
    def as_owfe_error

      result = svalue
      class << result
        attr_accessor :db_id
      end
      result.db_id = id
      result
    end

    alias :owfe_error :as_owfe_error
  end

  #
  # A database backed error journal.
  #
  # (no synchronization needed it seems)
  #
  class DbErrorJournal < OpenWFE::ErrorJournal
    include OpenWFE::FeiMixin

    # Returns the error log for a given workflow/process instance,
    # the older error first.
    #
    def get_error_log (wfid)

      wfid = extract_wfid(wfid, true)
      errors = ProcessError.find_all_by_wfid(wfid, :order => 'id asc')
      errors.collect { |e| e.as_owfe_error }
    end

    # Erases all the errors for one given workflow/process instance.
    #
    def remove_error_log (wfid)

      ProcessError.destroy_all([ 'wfid = ?', wfid ])
    end

    # Returns a map wfid => error log, ie returns 1 error log for
    # each workflow/process instance that encountered an error.
    #
    def get_error_logs

      ProcessError.find(:all).inject({}) do |h, e|
        (h[e.wfid] ||= []) << e.as_owfe_error; h
      end
    end

    # Removes a set of errors. This is used by the expool when
    # resuming a previously broken process instance.
    #
    def remove_errors (wfid, errors)

      Array(errors).each do |e|
        ProcessError.delete(e.db_id)
      end
    end

    protected

    # This is the inner method used by the error journal to
    # record a process error (instance of OpenWFE::ProcessError)
    # that it observed in the expression pool.
    #
    # This method will throw an exception in case of trouble with
    # the database.
    #
    def record_error (process_error)

      e = OpenWFE::Extras::ProcessError.new

      e.created_at = process_error.date
        # making sure they are, well, in sync

      e.wfid = process_error.wfid
      e.expid = process_error.fei.expid
      e.svalue = process_error

      e.save_without_transactions!
    end
  end
end

