#
#--
# Copyright (c) 2006-2009, Nicolas Modryzk and John Mettraux, OpenWFE.org
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
# Nicolas Modrzyk at openwfe.org
# John Mettraux at openwfe.org
#

require 'openwfe/engine/engine'
require 'openwfe/expool/yaml_expstorage'
require 'openwfe/expool/yaml_errorjournal'


module OpenWFE

  #
  # An engine persisted to a tree of yaml files.
  #
  # Remember that once you have added the participants to a persisted
  # engine, you should call its reload method, to reschedule expressions
  # like 'sleep', 'cron', ... But if you do it before registering the
  # participants you'll end up with broken processes.
  #
  class FilePersistedEngine < Engine

    protected

    #
    # Overrides the method already found in Engine with a persisted
    # expression storage
    #
    def build_expression_storage

      init_storage(YamlFileExpressionStorage)
    end

    #
    # Uses a file persisted error journal.
    #
    def build_error_journal

      init_service(:s_error_journal, YamlErrorJournal)
    end
  end

  #
  # An engine with a cache in front of its file persisted expression storage.
  #
  # Remember that once you have added the participants to a persisted
  # engine, you should call its reload method, to reschedule expressions
  # like 'sleep', 'cron', ... But if you do it before registering the
  # participants you'll end up with broken processes.
  #
  class CachedFilePersistedEngine < FilePersistedEngine

    protected

    def build_expression_storage

      init_storage(ThreadedYamlFileExpressionStorage)
    end
  end
end
