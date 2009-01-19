#
#--
# Copyright (c) 2007-2009, Tomaso Tosolini and John Mettraux, OpenWFE.org
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
# John Mettraux at openwfe.org
#

require 'openwfe/engine/engine'
require 'openwfe/extras/expool/db_expstorage'
require 'openwfe/extras/expool/db_errorjournal'


module OpenWFE::Extras

  #
  # A simple DbPersistedEngine, pure storage, no caching, no optimization.
  # For tests only.
  #
  class DbPersistedEngine < OpenWFE::Engine

    protected

      #
      # Overrides the method already found in Engine with a persisted
      # expression storage
      #
      def build_expression_storage

        init_service(:s_expression_storage, DbExpressionStorage)
      end

      #
      # Uses a file persisted error journal.
      #
      def build_error_journal

        init_service(:s_error_journal, DbErrorJournal)
      end
  end

  #
  # This OpenWFEru engine features database persistence (thanks to
  # ActiveRecord), with a cache (for faster read operations) and a
  # threaded wrapper (for buffering out unecessary write operations),
  # hence it's fast (of course its's slower than in-memory storage.
  #
  class CachedDbPersistedEngine < DbPersistedEngine

    protected

      def build_expression_storage

        @application_context[:expression_cache_size] ||= 1000

        init_service(:s_expression_storage, OpenWFE::CacheExpressionStorage)

        #init_service(:s_expression_storage__1, DbExpressionStorage)
        init_service(:s_expression_storage__1, ThreadedDbExpressionStorage)
      end
  end
end
