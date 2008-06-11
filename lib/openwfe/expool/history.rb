#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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
# John Mettraux at openwfe.org
#

require 'openwfe/service'
require 'openwfe/omixins'
require 'openwfe/rudefinitions'


module OpenWFE

  #
  # A Mixin for history modules
  #
  module HistoryMixin
    include ServiceMixin
    include OwfeServiceLocator

    def service_init (service_name, application_context)

      super

      get_expression_pool.add_observer(:all) do |event, *args|
        log(event, *args)
      end
    end

    def log (event, *args)
      raise NotImplementedError.new(
        "please provide an implementation of log(e, fei, wi)")
    end
  end

  #
  # A base implementation for InMemoryHistory and FileHistory.
  #
  class History
    include HistoryMixin
    include FeiMixin


    def initialize (service_name, application_context)

      super()

      service_init(service_name, application_context)
    end

    def log (event, *args)

      return if event == :update
      return if event == :reschedule
      return if event == :stop

      msg = "#{Time.now.to_s} -- "

      msg << event.to_s

      if args.length > 0
        fei = extract_fei args[0]
        msg << " #{fei.to_s}"
      end

      #msg << " #{args[1].to_s}" \
      #  if args.length > 1

      @output << msg + "\n"
    end
  end

  #
  # The simplest implementation, stores all history entries in memory.
  #
  # DO NOT USE IN PRODUCTION, it will trigger an 'out of memory' error
  # sooner or later.
  #
  # Is only used for unit testing purposes.
  #
  class InMemoryHistory < History

    def initialize (service_name, application_context)

      super

      @output = []
    end

    #
    # Returns the array of entries.
    #
    def entries
      @output
    end

    #
    # Returns all the entries as a String.
    #
    def to_s
      @output.inject("") { |r, entry| r << entry.to_s }
    end
  end

  #
  # Simply dumps the history in the work directory in a file named
  # "history.log"
  # Warning : no fancy rotation or compression implemented here.
  #
  class FileHistory < History

    def initialize (service_name, application_context)

      super

      @output = get_work_directory + "/history.log"
      @output = File.open(@output, "w+")

      linfo { "new() outputting history to #{@output.path}" }
    end

    #
    # Returns a handle on the output file instance used by this
    # FileHistory.
    #
    def output_file
      @output
    end

    def stop
      @output.close
    end
  end

end

