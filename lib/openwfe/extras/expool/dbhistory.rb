#
#--
# Copyright (c) 2008-2009, John Mettraux, OpenWFE.org
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
# John Mettraux
#

#require_gem 'activerecord'
gem 'activerecord'; require 'active_record'

require 'openwfe/expool/history'


module OpenWFE::Extras

  #
  # The migration for the DbHistory table
  #
  class HistoryTables < ActiveRecord::Migration

    def self.up

      create_table :history do |t|

        t.column :created_at, :timestamp
        t.column :source, :string, :null => false
        t.column :event, :string, :null => false
        t.column :wfid, :string
        t.column :fei, :string
        t.column :participant, :string
        t.column :message, :string # empty is ok
      end

      add_index :history, :created_at
      add_index :history, :source
      add_index :history, :event
      add_index :history, :wfid
      add_index :history, :participant
    end

    def self.down

      drop_table :history
    end
  end

  #
  # The active record for process errors. Not much to say.
  #
  class HistoryEntry < ActiveRecord::Base

    set_table_name('history')

    #
    # returns a FlowExpressionId instance if the entry has a 'fei' or
    # nil instead.
    #
    def full_fei

      self.fei ? OpenWFE::FlowExpressionId.from_s(self.fei) : nil
    end
  end

  class DbHistory < OpenWFE::History

    #def initialize (service_name, application_context)
    #  super
    #end

    def log (source, event, *args)

      do_log(source, event, args)
    end

    protected

      def do_log (source, event, *args)


        fei = get_fei(args)

        he = HistoryEntry.new

        he.source = source.to_s
        he.event = event.to_s

        if fei
          he.wfid = fei.parent_wfid
          he.fei = fei.to_s
        end

        he.message = get_message(source, event, args)

        wi = get_workitem(args)

        he.participant = wi.participant_name \
          if wi.respond_to?(:participant_name)

        begin
          he.save!
        rescue Exception => e
          #p e
          lerror { "dbhistory logging failure : #{e}" }
        end
      end
  end

  #
  # An extension of the DbHistory that uses the engine's workqueue. Insertions
  # into database are queued (as well as expool events).
  #
  # Seems to be slightly faster (0.8s gain for a 11s test).
  #
  # Currently in use in ruote-rest.
  #
  class QueuedDbHistory < DbHistory

    def log (source, event, *args)

      get_workqueue.push(self, :do_log, source, event, *args)
    end
  end

end

