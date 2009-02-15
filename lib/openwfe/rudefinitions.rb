#
#--
# Copyright (c) 2006-2009, John Mettraux, OpenWFE.org
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

require 'fileutils'

require 'openwfe/utils'
require 'openwfe/version'


module OpenWFE

  #
  # service names

  #S_LOGGER = :logger

  #
  # some special expression names

  EN_ENVIRONMENT = 'environment'

  #
  # some file storage default values

  DEFAULT_WORK_DIRECTORY = 'work'

  #
  # A mixin for easy OpenWFE service lookup
  # (assumes the presence of an application context instance var)
  #
  module OwfeServiceLocator

    def get_engine
      @application_context[:s_engine]
    end
    def get_scheduler
      @application_context[:s_scheduler]
    end
    def get_expression_map
      @application_context[:s_expression_map]
    end
    def get_wfid_generator
      @application_context[:s_wfid_generator]
    end
    def get_workqueue
      @application_context[:s_workqueue]
    end
    def get_expool
      @application_context[:s_expression_pool]
    end
    def get_expression_pool
      @application_context[:s_expression_pool]
    end
    def get_expression_storage
      @application_context[:s_expression_storage]
    end
    def get_participant_map
      @application_context[:s_participant_map]
    end
    def get_error_journal
      @application_context[:s_error_journal]
    end
    def get_tree_checker
      @application_context[:s_tree_checker]
    end
    def get_def_parser
      @application_context[:s_def_parser]
    end

    #
    # Returns the 'journal' service (or nil if there is no
    # journal service available).
    #
    def get_journal
      @application_context[:s_journal]
    end

    #
    # Returns all the expression storage in the application context
    # (there is usually a cache and a persisted exp storage).
    #
    def get_expression_storages

      @application_context.inject([]) do |r, (k, v)|
        r << v if k.to_s.match(/^s_expression_storage/)
        r
      end
    end
  end

end

