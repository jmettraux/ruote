#
#--
# Copyright (c) 2005-2007, John Mettraux, OpenWFE.org
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
# "hecho en Costa Rica"
#
# john.mettraux@openwfe.org
#

require 'base64'

require 'openwfe/utils'


module OpenWFE

    #--
    # HISTORY ITEM
    #
    # (currently not used in OpenWFEru itself :( )
    #++

    #
    # HistoryItem instances are used to keep track of what happened to
    # a workitem.
    #
    class HistoryItem

        attr_accessor \
            :date,
            :author,
            :host,
            :text,
            :wfd_name,
            :wfd_revision,
            :wf_instance_id,
            :expression_id
        
        def dup
            OpenWFE::fulldup(self)
        end
    end


    #--
    # STORES
    #++

    #
    # Models the information about a store as viewed by the current user 
    # (upon calling the listStores or getStoreNames methods)
    #
    class Store

        attr_accessor :name, :workitem_count, :permissions

        def initialize ()
            super()
            #@name = nil
            #@workitem_count = nil
            #@permissions = nil
        end

        #
        # Returns true if the current user may read headers and workitems
        # from this store
        #
        def may_read? ()
            return @permissions.index('r') > -1
        end

        #
        # Returns true if the current user may modify workitems (and at least
        # proceed/forward them) in this store
        #
        def may_write? ()
            @permissions.index('w') > -1
        end

        #
        # Returns true if the current user may browse the headers of this
        # store
        #
        def may_browse? ()
            @permissions.index('b') > -1
        end

        #
        # Returns true if the current user may delegate workitems to this store
        #
        def may_delegate? ()
            @permissions.index('d') > -1
        end
    end

    #
    # A header is a summary of a workitem, returned by the getHeader
    # worklist method.
    #
    # (Only used when accessing an OpenWFEja engine)
    #
    class Header < InFlowWorkItem

        attr_accessor :locked
    end


    #--
    # MISC ATTRIBUTES
    #
    # in openwfe-ruby, OpenWFE attributes are immediately mapped to
    # Ruby instances, but some attributes still deserve their own class
    #
    # (Only used when accessing an OpenWFEja engine)
    #++

    #
    # a wrapper for some binary content
    #
    class Base64Attribute

        attr_accessor :content

        def initialize (base64content)

            @content = base64content
        end

        #
        # dewraps (decode) the current content and returns it
        #
        def dewrap ()

            Base64.decode64(@content)
        end

        #
        # wraps some binary content and stores it in this attribute
        # (class method)
        #
        def Base64Attribute.wrap (binaryData)

            Base64Attribute.new(Base64.encode64(binaryData))
        end
    end


    #--
    # LAUNCHABLE
    #++

    #
    # A worklist will return list of Launchable instances indicating
    # what processes (URL) a user may launch on which engine.
    #
    # (Only used when accessing an OpenWFEja engine)
    #
    class Launchable

        attr_accessor :url, :engine_id
    end


    #
    # Expression, somehow equivalent to FlowExpression, but only used 
    # by the control interface.
    #
    # (Only used when accessing an OpenWFEja engine)
    #
    class Expression

        attr_accessor :id, :apply_time, :state, :state_since
    end

end

