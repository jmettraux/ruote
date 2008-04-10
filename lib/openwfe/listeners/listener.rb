#
#--
# Copyright (c) 2007, John Mettraux, OpenWFE.org
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

require 'openwfe/logging'
require 'openwfe/workitem'
require 'openwfe/contextual'


module OpenWFE

    #
    # this mixin module provides two protected methods, handle_item() and
    # filter_item(). They can be easily overriden to add some special
    # behaviours.
    #
    module WorkItemListener
        include Contextual, Logging, OwfeServiceLocator

        protected

            #
            # Simply considers the object as a workitem and feeds it to the 
            # engine.
            #
            def handle_item (item)

                filter_items item

                get_engine.reply item
            end

            #
            # The base implementation is just empty, feel free to override it
            # if you need to filter workitems.
            #
            # One example :
            #
            #     class MyListener
            #         include WorkItemListener
            #
            #         protected
            #
            #             #
            #             # MyListener doesn't accept launchitems
            #             #
            #             def filter_items (item)
            #                 raise "launchitems not allowed" \
            #                     if item.is_a?(OpenWFE::LaunchItem)
            #             end
            #     end
            #
            def filter_items (item)

                #raise(
                #    "listener of class '#{self.class.name}' "+
                #    "doesn't accept launchitems")
            end
    end

end

