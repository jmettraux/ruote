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

require 'find'
require 'yaml'
require 'fileutils'

require 'openwfe/service'
require 'openwfe/rudefinitions'
require 'openwfe/listeners/listener'


#
# some base listener implementations
#
module OpenWFE

    #
    # Polls a directory for incoming workitems (as files).
    #
    # Workitems can be instances of InFlowWorkItem or LaunchItem.
    #
    #     require 'openwfe/listeners/listeners'
    #
    #     engine.add_workitem_listener(OpenWFE::FileListener, "500")
    #
    # In this example, the directory ./work/in/ will be polled every 500
    # milliseconds for incoming workitems (or launchitems).
    #
    # You can override the load_object(path) method to manage other formats
    # then YAML.
    #
    class FileListener < Service
        include WorkItemListener
        include Rufus::Schedulable

        attr_reader :workdir

        def initialize (service_name, application_context)

            super

            @workdir = get_work_directory + "/in/"

            linfo { "new() workdir is '#{@workdir}'" }
        end

        #
        # Will 'find' files in the work directory (by default ./work/in/),
        # extract the workitem in them and feed it back to the engine.
        #
        def trigger (params)
            # no synchronization for now

            ldebug { "trigger()" }

            FileUtils.makedirs(@workdir) unless File.exist?(@workdir)

            Find.find(@workdir) do |path|

                next if File.stat(path).directory?

                ldebug { "trigger() considering file '#{path}'" }

                begin

                    object = load_object(path)

                    handle_item(object) if object

                rescue Exception => e

                    linfo do
                        "trigger() failure while loading from '#{path}'. " +
                        "Resuming... \n" +
                        OpenWFE::exception_to_s(e)
                    end
                end
            end
        end

        protected

            #
            # Turns a file into a Ruby instance.
            # This base implementation does it via YAML.
            #
            def load_object (path)

                return nil unless path.match ".*\.yaml$"

                object = YAML.load_file(path)

                File.delete(path)

                return object
            end
    end

end

