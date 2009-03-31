#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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
        r << v if k.to_s.match(/^s_expression_storage/); r
      end
    end
  end

end

