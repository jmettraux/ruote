#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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

#--
# this participant requires atom-tools from
#
# http://code.necronomicorp.com/trac/atom-tools
#
# atom-tools' license is X11/MIT
#++

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
    #   engine.init_service 'activityFeed', ActivityFeedService
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

      #ldebug "call() c '#{channel}' entries count : #{@entries.size}"

      e = Entry.new

      e.participant_name = channel
      e.upon = args[0]
      e.workitem = args[1].dup
      e.updated = Time.now

      e.id = \
        "#{e.workitem.participant_name} - #{e.upon} " +
        "#{e.workitem.fei.workflow_instance_id}--" +
        "#{e.workitem.fei.expression_id}"

      @entries << e

      while @entries.length > @max_item_count
        @entries.delete_at 0
      end
    end

    #
    # Returns an Atom feed of all the workitem activity for the
    # participants whose name matches the given regular expression.
    #
    # Options :
    #
    # [:upon]     can be set to either nil, :apply, :reply. :apply states
    #         that the returned feed should only contain entries about
    #         participant getting applied, :reply only about
    #         participant replying.
    # [:feed_uri]   the URI for the feed. Defaults to
    #         'http://localhost/feed'
    # [:feed_title] the title for the feed. Defaults to
    #         'OpenWFEru engine activity feed'
    # [:format]   yaml|text|json
    #
    #
    def get_feed (participant_regex, options={})

      participant_regex = Regexp.compile(participant_regex) \
        if participant_regex.is_a?(String)

      upon = options[:upon]
      feed_uri = options[:feed_uri] || "http://localhost/feed"
      title = options[:feed_title] || "OpenWFEru engine activity feed"

      feed = Atom::Feed.new feed_uri
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
      #  def convert_contents e
      #    REXML::CData.new(@content.to_s)
      #  end
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

