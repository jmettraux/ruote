#--
# Copyright (c) 2006-2009, Nicolas Modryzk and John Mettraux, OpenWFE.org
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


require 'openwfe/engine/engine'
require 'openwfe/expool/fs_expstorage'
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
  # DEPRECATED, use FsEngine instead
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
  # DEPRECATED, use FsEngine instead
  #
  class CachedFilePersistedEngine < FilePersistedEngine

    protected

    def build_expression_storage

      init_storage(ThreadedYamlFileExpressionStorage)
    end
  end
end
