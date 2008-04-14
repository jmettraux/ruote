#
#--
# Copyright (c) 2005-2008, John Mettraux, OpenWFE.org
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
# "hecho en Costa Rica" (with just the PickAxe at hand)
#

require 'base64'
require 'rexml/document'

require 'openwfe/utils'
require 'openwfe/workitem'
require 'openwfe/flowexpressionid'
require 'openwfe/orest/definitions'
require 'openwfe/orest/workitem'


module OpenWFE

    #
    # Ugly XML codec for OpenWFE workitems
    #
    # (one of the first things I wrote in Ruby...)
    #
    module XmlCodec

        #
        # Returns the first subelt of xmlElt that matches the given elt_name.
        # If the name is null, the first elt will be returned.
        #
        def self.first_element (xml_elt, elt_name=nil)

            return nil if not xml_elt

            return xml_elt.elements.find { |e| e.is_a?(REXML::Element) } \
                unless elt_name

            xml_elt.elements.find do |e| 
                e.is_a?(REXML::Element) and e.name == elt_name
            end
        end

        #
        # Takes as input some XML element and returns is decoded 
        # (as an instance)
        #
        def XmlCodec.decode (xmlElt)

            return nil unless xmlElt

            if xmlElt.kind_of? String

                xmlElt = REXML::Document.new(
                    xmlElt, 
                    :compress_whitespace => :all,
                    :ignore_whitespace_nodes => :all)

                xmlElt = xmlElt.root
            end

            #puts "decode() xmlElt.name is >#{xmlElt.name}<"

            return decode_session_id(xmlElt) if xmlElt.name == 'session'
            return decode_list(xmlElt) if xmlElt.name == STORES
            return decode_store(xmlElt) if xmlElt.name == STORE
            return decode_list(xmlElt) if xmlElt.name == HEADERS
            return decode_header(xmlElt) if xmlElt.name == HEADER

            return decode_launch_ok(xmlElt) if xmlElt.name == OK

            return decode_list(xmlElt) if xmlElt.name == HISTORY
            return decode_historyitem(xmlElt) if xmlElt.name == HISTORY_ITEM

            return decode_list(xmlElt) if xmlElt.name == FLOW_EXPRESSION_IDS
            return decode_fei(xmlElt) if xmlElt.name == FLOW_EXPRESSION_ID

            return decode_inflowworkitem(xmlElt) \
                if xmlElt.name == IN_FLOW_WORKITEM
            return decode_launchitem(xmlElt) \
                if xmlElt.name == LAUNCHITEM

            return decode_list(xmlElt) if xmlElt.name == LAUNCHABLES
            return decode_launchable(xmlElt) if xmlElt.name == LAUNCHABLE

            return decode_list(xmlElt) if xmlElt.name == EXPRESSIONS
            return decode_expression(xmlElt) if xmlElt.name == EXPRESSION

            return decode_attribute(xmlElt.elements[1]) if xmlElt.name == ATTRIBUTES

            #
            # default

            decode_attribute(xmlElt)

            #raise \
            #    ArgumentError, \
            #    "Cannot decode : '"+xmlElt.name+"' "+xmlElt.to_s()
        end

        #
        # Takes some OpenWFE Ruby instance and returns it as XML
        #
        def XmlCodec.encode (owfeData)

            #puts "encode() #{owfeData.inspect}"

            return encode_launchitem(owfeData) \
                if owfeData.kind_of? LaunchItem

            return encode_fei(owfeData) \
                if owfeData.kind_of? FlowExpressionId

            return encode_inflowworkitem(owfeData) \
                if owfeData.kind_of? InFlowWorkItem

            raise \
                ArgumentError, \
                "Cannot encode : "+owfeData.inspect()
        end

        def XmlCodec.encode_workitem_as_header (in_flow_workitem, locked)

            e = REXML::Element.new HEADER

            e.add_attribute A_LAST_MODIFIED, "#{in_flow_workitem.last_modified}"
            e.add_attribute A_LOCKED, locked

            e << XmlCodec::encode_fei(in_flow_workitem.fei)
            e << XmlCodec::encode_attributes(in_flow_workitem)

            e
        end

        private

            #
            # DECODE
            #

            def XmlCodec.decode_session_id (xmlElt)
                Integer(xmlElt.attributes['id'])
            end

            def XmlCodec.decode_list (xmlElt)
                xmlElt.elements.collect { |elt| decode(elt) }
            end


            def XmlCodec.decode_launchable (xmlElt)

                launchable = Launchable.new()

                launchable.url = xmlElt.attributes[URL]
                launchable.engine_id = xmlElt.attributes[ENGINE_ID]

                launchable
            end


            def XmlCodec.decode_expression (xmlElt)

                exp = Expression.new()
                
                exp.id = decode(first_element(xmlElt))

                exp.apply_time = xmlElt.attributes[APPLY_TIME]
                exp.state = xmlElt.attributes[STATE]
                exp.state_since = xmlElt.attributes[STATE_SINCE]

                exp
            end


            def XmlCodec.decode_store (xmlElt)

                store = Store.new()

                store.name = xmlElt.attributes[NAME]
                store.workitem_count = xmlElt.attributes[WORKITEM_COUNT]
                store.workitem_count = Integer(store.workitem_count)
                store.permissions = xmlElt.attributes[PERMISSIONS]

                store
            end


            def XmlCodec.decode_header (xmlElt)

                header = Header.new()

                header.last_modified = xmlElt.attributes[A_LAST_MODIFIED]
                header.locked = parse_boolean(xmlElt.attributes[A_LOCKED])
                header.flow_expression_id = decode(first_element(xmlElt, FLOW_EXPRESSION_ID))
                header.attributes = decode(first_element(xmlElt, ATTRIBUTES))

                header
            end


            def XmlCodec.decode_fei (xmlElt)

                fei = FlowExpressionId.new

                fei.owfe_version = xmlElt.attributes[OWFE_VERSION]
                fei.engine_id = xmlElt.attributes[ENGINE_ID]
                fei.initial_engine_id = xmlElt.attributes[INITIAL_ENGINE_ID]

                fei.workflow_definition_url = xmlElt.attributes[WORKFLOW_DEFINITION_URL]
                fei.workflow_definition_name = xmlElt.attributes[WORKFLOW_DEFINITION_NAME]
                fei.workflow_definition_revision = xmlElt.attributes[WORKFLOW_DEFINITION_REVISION]

                fei.workflow_instance_id = xmlElt.attributes[WORKFLOW_INSTANCE_ID]

                fei.expression_name = xmlElt.attributes[EXPRESSION_NAME]
                fei.expression_id = xmlElt.attributes[EXPRESSION_ID]

                #puts " ... fei.expressionName is >#{fei.expressionName}<"
                #puts " ... fei.wfid is >#{fei.workflowInstanceId}<"

                fei
            end


            def XmlCodec.decode_attribute (xmlElt)

                #puts "decodeAttribute() '#{xmlElt.name}' --> '#{xmlElt.text}'"

                #
                # atomic types

                return xmlElt.text.strip \
                    if xmlElt.name == E_STRING
                return Integer(xmlElt.text.strip) \
                    if xmlElt.name == E_INTEGER
                return Integer(xmlElt.text.strip) \
                    if xmlElt.name == E_LONG
                return Float(xmlElt.text.strip) \
                    if xmlElt.name == E_DOUBLE
                return parse_boolean(xmlElt.text) \
                    if xmlElt.name == E_BOOLEAN

                return decode_xmldocument(xmlElt) \
                    if xmlElt.name == E_XML_DOCUMENT
                return xmlElt.children[0] \
                    if xmlElt.name == E_RAW_XML

                return Base64Attribute.new(xmlElt.text) \
                    if xmlElt.name == E_BASE64

                #
                # composite types

                return decode_list(xmlElt) \
                    if xmlElt.name == E_LIST

                if xmlElt.name == E_SMAP or xmlElt.name == E_MAP

                    map = {}
                    map[MAP_TYPE] = xmlElt.name

                    #xmlElt.elements.each("//"+M_ENTRY) do |e| 
                    xmlElt.elements.each(M_ENTRY) do |e| 
                        #puts "decodeAttribute() >#{e}<"
                        decode_entry(e, map)
                    end

                    return map
                end

                #puts OpenWFE.xmldoc_to_string(xmlElt.document())

                raise \
                    ArgumentError, \
                    "Cannot decode <#{xmlElt.name}/> in \n"+\
                    OpenWFE.xmldoc_to_string(xmlElt.document())
            end

            def XmlCodec.decode_xmldocument (xmlElt)

                s = Base64::decode64 xmlElt.text.strip
                REXML::Document.new s
            end

            def XmlCodec.decode_entry (xmlElt, map)

                key = xmlElt.elements[1]
                val = xmlElt.elements[2]

                #
                # this parse method supports the old style and the [new] light
                # style/schema
                #

                key = key.elements[1] if key.name == M_KEY
                val = val.elements[1] if val.name == M_VALUE

                key = decode(key)
                val = decode(val)

                #puts "decodeEntry() k >#{key}< v >#{val}<"
                #puts "decodeEntry() subject '#{val}'" if key == '__subject__' 

                key = key.strip if key.is_a?(String)
                val = val.strip if val.is_a?(String)

                map[key] = val
            end

            def XmlCodec.parse_boolean (string)

                string.strip.downcase == 'true'
            end

            def XmlCodec.decode_historyitem (xmlElt)

                hi = HistoryItem.new

                hi.author = xmlElt.attributes[A_AUTHOR]
                hi.date = xmlElt.attributes[A_DATE]
                hi.host = xmlElt.attributes[A_HOST]
                hi.text = xmlElt.text

                hi.wfd_name = xmlElt.attributes[WORKFLOW_DEFINITION_NAME]
                hi.wfd_revision = xmlElt.attributes[WORKFLOW_DEFINITION_REVISION]
                hi.wf_instance_id = xmlElt.attributes[WORKFLOW_INSTANCE_ID]
                hi.expression_id = xmlElt.attributes[EXPRESSION_ID]

                hi
            end


            def XmlCodec.decode_launch_ok (xmlElt)

                sFei = xmlElt.attributes[A_FLOW_ID]

                return true unless sFei

                FlowExpressionId.to_fei(sFei)
            end


            def XmlCodec.decode_inflowworkitem (xmlElt)

                wi = InFlowWorkItem.new()

                wi.last_modified = xmlElt.attributes[A_LAST_MODIFIED]
                wi.attributes = decode(first_element(xmlElt, ATTRIBUTES))

                wi.participant_name = xmlElt.attributes[A_PARTICIPANT_NAME]
                wi.flow_expression_id = decode(first_element(first_element(xmlElt, E_LAST_EXPRESSION_ID), FLOW_EXPRESSION_ID))

                wi.dispatch_time = xmlElt.attributes[A_DISPATCH_TIME]

                # TODO : decode filter

                wi.history = decode(first_element(xmlElt, HISTORY))

                wi
            end

            def XmlCodec.decode_launchitem (xmlElt)

                li = LaunchItem.new

                li.workflow_definition_url = 
                    xmlElt.attributes[WORKFLOW_DEFINITION_URL]

                li.attributes = 
                    decode(first_element(xmlElt, ATTRIBUTES))

                li
            end


            #
            # ENCODE
            #


            def XmlCodec.encode_item (item, elt)

                elt.attributes[A_LAST_MODIFIED] = item.last_modified

                elt << encode_attributes(item)
            end

            def XmlCodec.encode_attributes (item)

                eAttributes = REXML::Element.new(ATTRIBUTES)

                eAttributes << encode_attribute(item.attributes)

                eAttributes
            end


            def XmlCodec.encode_launchitem (launchitem)

                doc = REXML::Document.new()

                root = REXML::Element.new(LAUNCHITEM)

                encode_item(launchitem, root)

                root.attributes[WORKFLOW_DEFINITION_URL] = \
                    launchitem.workflow_definition_url

                # TODO :
                #
                # - encode descriptionMap
                #
                # - replyTo is not necessary

                doc << root

                OpenWFE.xmldoc_to_string(doc)
            end


            def XmlCodec.encode_inflowitem (item, elt)

                encode_item(item, elt)

                elt.attributes[A_PARTICIPANT_NAME] = item.participant_name

                eLastExpressionId = REXML::Element.new(E_LAST_EXPRESSION_ID)

                eLastExpressionId << encode_fei(item.last_expression_id)

                elt << eLastExpressionId
            end


            def XmlCodec.encode_inflowworkitem (item)

                doc = REXML::Document.new()

                root = REXML::Element.new(IN_FLOW_WORKITEM)

                encode_inflowitem(item, root)

                root.attributes[A_DISPATCH_TIME] = item.dispatch_time

                # add filter ? no

                encode_history(item, root) if item.history

                doc << root

                s = OpenWFE.xmldoc_to_string(doc)
                #puts "encoded :\n#{s}"
                s
            end


            def XmlCodec.encode_history (item, elt)

                eHistory = REXML::Element.new(HISTORY)

                item.history.each do |hi|

                    ehi = REXML::Element.new(HISTORY_ITEM)

                    ehi.attributes[A_AUTHOR] = hi.author
                    ehi.attributes[A_DATE] = hi.date
                    ehi.attributes[A_HOST] = hi.host

                    ehi.attributes[WORKFLOW_DEFINITION_NAME] = hi.wfd_name
                    ehi.attributes[WORKFLOW_DEFINITION_REVISION] = hi.wfd_revision
                    ehi.attributes[WORKFLOW_INSTANCE_ID] = hi.wf_instance_id
                    ehi.attributes[EXPRESSION_ID] = hi.expression_id

                    eHistory << ehi
                end

                elt << eHistory
            end


            def XmlCodec.encode_attribute (att)

                #puts "encodeAttribute() att.class is #{att.class}"

                return encode_atomicattribute(E_STRING, att) \
                    if att.kind_of?(String)
                return encode_atomicattribute(E_INTEGER, att) \
                    if att.kind_of?(Fixnum)
                return encode_atomicattribute(E_DOUBLE, att) \
                    if att.kind_of?(Float)

                return encode_xmldocument(att) \
                    if att.kind_of?(REXML::Document)
                return encode_xmlattribute(att) \
                    if att.kind_of?(REXML::Element)

                return encode_atomicattribute(E_BOOLEAN, true) \
                    if att.kind_of?(TrueClass)
                return encode_atomicattribute(E_BOOLEAN, false) \
                    if att.kind_of?(FalseClass)

                return encode_base64attribute(att) \
                    if att.kind_of?(Base64Attribute)

                return encode_mapattribute(att) if att.kind_of?(Hash)
                return encode_listattribute(att) if att.kind_of?(Array)

                #
                # default

                encode_atomicattribute(E_STRING, att)

                #raise \
                #    ArgumentError, \
                #    "Cannot encode attribute of class '#{att.class}'"
            end

            def XmlCodec.encode_xmldocument (elt)

                e = REXML::Element.new(E_XML_DOCUMENT)
                e.text = Base64::encode64(elt.to_s)
                e
            end

            def XmlCodec.encode_xmlattribute (elt)

                return elt if elt.name == E_RAW_XML

                #
                # else, wrap within <raw-xml>...</raw-xml>

                e = REXML::Element.new(E_RAW_XML)
                e << elt

                e
            end


            def XmlCodec.encode_base64attribute (att)

                e = REXML::Element.new(E_BASE64)
                e.text = att.content

                e
            end


            def XmlCodec.encode_atomicattribute (name, value)

                elt = REXML::Element.new(name)
                #elt << REXML::Text.new(value.to_s())
                elt.add_text(value.to_s())

                elt
            end


            def XmlCodec.encode_listattribute (list)

                elt = REXML::Element.new(E_LIST)

                list.each do |e|
                    elt << encode_attribute(e)
                end

                elt
            end


            def XmlCodec.encode_mapattribute (hash)

                name = hash[MAP_TYPE]
                name = 'map' if name == nil

                elt = REXML::Element.new(name)

                hash.each_key do |key|

                    next if key == MAP_TYPE

                    eEntry = REXML::Element.new(M_ENTRY)

                    val = hash[key]

                    eEntry << encode_attribute(key)
                    eEntry << encode_attribute(val)

                    elt << eEntry
                end

                elt
            end


            def XmlCodec.encode_fei (fei)

                elt = REXML::Element.new(FLOW_EXPRESSION_ID)

                elt.attributes[OWFE_VERSION] = fei.owfe_version
                elt.attributes[ENGINE_ID] = fei.engine_id
                elt.attributes[INITIAL_ENGINE_ID] = fei.initial_engine_id

                elt.attributes[WORKFLOW_DEFINITION_URL] = fei.workflow_definition_url
                elt.attributes[WORKFLOW_DEFINITION_NAME] = fei.workflow_definition_name
                elt.attributes[WORKFLOW_DEFINITION_REVISION] = fei.workflow_definition_revision
                elt.attributes[WORKFLOW_INSTANCE_ID] = fei.workflow_instance_id

                elt.attributes[EXPRESSION_NAME] = fei.expression_name
                elt.attributes[EXPRESSION_ID] = fei.expression_id

                elt
            end
    end

    #
    # Just turns some XML to a String (if decl is set to false, no 
    # XML declaration will be printed).
    #
    def OpenWFE.xmldoc_to_string (xml, decl=true)

        #return xml if xml.is_a?(String)

        xml << REXML::XMLDecl.new \
            if decl and (not xml[0].is_a?(REXML::XMLDecl))

        #s = ""
        #xml.write(s, 0)
        #return s
        xml.to_s
    end

    #
    # An alias for OpenWFE::xmldoc_to_string()
    #
    def OpenWFE.xml_to_s (xml, decl=true)

        OpenWFE::xmldoc_to_string(xml, decl)
    end

end

