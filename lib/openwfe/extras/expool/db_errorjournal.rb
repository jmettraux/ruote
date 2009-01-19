#
#--
# Copyright (c) 2007-2009, Tomaso Tosolini, John Mettraux, OpenWFE.org
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

require 'openwfe/omixins'
require 'openwfe/expool/errorjournal'


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

        t.column :wfid, :string, :null => false
        t.column :expid, :string, :null => false
        t.column :svalue, :text, :null => false
          # 'value' could be reserved, using 'svalue' instead
          # It stands for 'serialized value'.
      end
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

    serialize :svalue

    #
    # Returns the OpenWFE process error, as serialized
    # (but takes care of setting its db_id)
    #
    def owfe_error

      result = svalue
      class << result
        attr_accessor :db_id
      end
      result.db_id = id
      result
    end
  end

  #
  # A database backed error journal.
  #
  # (no synchronization needed it seems)
  #
  class DbErrorJournal < OpenWFE::ErrorJournal
    include OpenWFE::FeiMixin

    def initialize (service_name, application_context)

      require 'openwfe/storage/yaml_custom'
        # making sure this file has been required at this point
        # this yamlcustom thing prevents the whole OpenWFE ecosystem
        # to get serialized :)

      super
    end

    #
    # Returns the error log for a given workflow/process instance,
    # the older error first.
    #
    def get_error_log (wfid)

      wfid = extract_wfid(wfid, true)
      errors = ProcessError.find_all_by_wfid(wfid, :order => 'id asc')
      errors.collect { |e| e.owfe_error }
    end

    #
    # Erases all the errors for one given workflow/process instance.
    #
    def remove_error_log (wfid)

      ProcessError.destroy_all([ 'wfid = ?', wfid ])
    end

    #
    # Returns a map wfid => error log, ie returns 1 error log for
    # each workflow/process instance that encountered an error.
    #
    def get_error_logs

      ProcessError.find(:all).inject({}) do |h, e|
        (h[e.wfid] ||= []) << e.owfe_error; h
      end
    end

    #
    # Removes a set of errors. This is used by the expool when
    # resuming a previously broken process instance.
    #
    def remove_errors (wfid, errors)

      Array(errors).each do |e|
        ProcessError.delete(e.db_id)
      end
    end

    protected

      #
      # This is the inner method used by the error journal to
      # record a process error (instance of OpenWFE::ProcessError)
      # that it observed in the expression pool.
      #
      # This method will throw an exception in case of trouble with
      # the database.
      #
      def record_error (process_error)

        e = ProcessError.new

        e.wfid = process_error.wfid
        e.expid = process_error.expid
        e.svalue = process_error

        e.save!
      end
  end
end

