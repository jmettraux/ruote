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

#
# this participant requires atom-tools from
#
# http://code.necronomicorp.com/trac/atom-tools 
#
# atom-tools' license is X11/MIT
#

#require 'monitor'

#require 'rubygems'
require 'atom/collection' # gem 'atoom-tools'

require 'openwfe/service'



module OpenWFE::Extras

    #
    # A workitem event as kept
    #
    class Entry

        attr_accessor :id
        attr_accessor :updated

        attr_accessor :participant_name
        attr_accessor :upon
        attr_accessor :workitem

        def initialize

            @update = Time.now
        end

        def as_atom_entry

            e = Atom::Entry.new

            e.id = @id
            e.updated = @updated

            e
        end
    end

    #
    # This feed registers as an observer to the ParticipantMap.
    # Each time a workitem is delivered to a participant or comes back from/for
    # it, an AtomEntry is generated.
    # The get_feed() method produces an atom feed of participant activity.
    #
    class ActivityFeedService
        #include MonitorMixin
        include OpenWFE::ServiceMixin
        include OpenWFE::OwfeServiceLocator 


        attr_accessor :max_item_count


        #
        # This service is generally tied to an engine by doing :
        #
        #     engine.init_service 'activityFeed', ActivityFeedService
        #
        # The init_service() will take care of calling the constructor
        # implemented here.
        #
        def initialize (service_name, application_context)

            super()

            service_init service_name, application_context

            @entries = []
            @max_item_count = 100

            get_participant_map.add_observer ".*", self
        end

        #
        # This is the method call by the expression pool each time a
        # workitem reaches a participant.
        #
        def call (channel, *args)

            ldebug "call() c '#{channel}' entries count : #{@entries.size}"

            e = Entry.new

            e.participant_name = channel
            e.upon = args[0]
            e.workitem = args[1].dup

            e.id = \
                "#{e.workitem.participant_name} - #{e.upon} " +
                "#{e.workitem.fei.workflow_instance_id}--" +
                "#{e.workitem.fei.expression_id}"

            @entries << e

            @entries = @entries[0, @max_item_count] \
                if @entries.length > @max_item_count
        end

        #
        # Returns an Atom feed of all the workitem activity for the 
        # participants whose name matches the given regular expression.
        #
        # Options :
        #
        # [:upon]       can be set to either nil, :apply, :reply. :apply states
        #               that the returned feed should only contain entries about
        #               participant getting applied, :reply only about 
        #               participant replying.
        # [:feed_uri]   the URI for the feed. Defaults to 
        #               'http://localhost/feed'
        # [:feed_title] the title for the feed. Defaults to 
        #               'OpenWFEru engine activity feed'
        # [:format]     yaml|text|json
        #
        #
        def get_feed (participant_regex, options={})

            participant_regex = Regexp.compile(participant_regex) \
                if participant_regex.is_a?(String)

            upon = options[:upon]
            feed_uri = options[:feed_uri] || "http://localhost/feed"
            title = options[:feed_title] || "OpenWFEru engine activity feed"

            feed = Atom::Collection.new feed_uri
            feed.title = title

            format = options[:format]
            format = validate_format(format)

            @entries.each do |e|

                next unless participant_regex.match(e.participant_name)
                next if upon and upon != e.upon

                feed.updated = e.updated \
                    if feed.updated == nil or e.updated > feed.updated

                feed << as_atom_entry(format, e)
            end

            feed
        end

        protected

            #
            # Makes sure the required 'render' is valid. Returns it
            # as a Symbol.
            #
            def validate_format (f)

                f = "as_#{f}"
                return :as_yaml unless methods.include?(f)
                f.to_sym
            end

            def as_atom_entry (render, entry)

                send(
                    render, 
                    entry.as_atom_entry, 
                    entry.participant_name, 
                    entry.upon, 
                    entry.workitem)
            end

            #
            # A basic rendition of a workitem as a YAML string
            #
            def as_yaml (atom_entry, participant_name, upon, workitem)

                atom_entry.title = "#{participant_name} - #{upon}"
                atom_entry.content = workitem.to_yaml
                atom_entry.content['type'] = "text/plain"

                atom_entry
            end

            #class Atom::Content
            #    def convert_contents e
            #        REXML::CData.new(@content.to_s)
            #    end
            #end

            #
            # A basic rendition of a workitem as text.
            #
            def as_text (atom_entry, participant_name, upon, workitem)

                atom_entry.title = "#{participant_name} - #{upon}"

                atom_entry.content = workitem.to_s
                atom_entry.content['type'] = "text/plain"

                atom_entry
            end

            #
            # Renders the workitem as a JSON string.
            #
            def as_json (atom_entry, participant_name, upon, workitem)

                atom_entry.title = "#{participant_name} - #{upon}"

                atom_entry.content = workitem.to_json
                atom_entry.content['type'] = "text/plain"

                atom_entry
            end
    end

end

