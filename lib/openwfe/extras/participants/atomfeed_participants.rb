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

require 'monitor'

require 'atom/collection' # gem 'atom-tools'

require 'openwfe/participants/participant'


module OpenWFE::Extras

  #
  # Stores the incoming workitem into an 'atom feed'
  #
  # An example :
  #
  #   feed0 = AtomFeedParticipant.new(
  #     20,              # no more than 20 entries are kept
  #     """
  #     <p>
  #       <h1>${f:colour}</h1>
  #     </p>
  #     """)             # the template for each entry
  #
  # The 'template' parameter may contain an instance of File instead of
  # an instance of String.
  #
  #   feed0 = AtomFeedParticipant.new(
  #     20, File.new("path/to/my/atom/template.txt")
  #
  # The template can be passed as the second parameter (after the max entry
  # count) or as a block :
  #
  #   feed1 = AtomFeedParticipant.new(20) do |flow_expression, atom_participant, workitem|
  #     #
  #     # usually only the workitem parameter is used
  #     # but the other two allow for advanced tricks...
  #
  #     atom_participant.content_type = "xml"
  #       # by default, it's "xhtml"
  #
  #     s = "<task>"
  #     s << "<name>#{workitem.task_name}</name>"
  #     s << "<assignee>#{workitem.task_assignee}</assignee>"
  #     s << "<duedate>#{workitem.task_duedate}</duedate>"
  #     s << "</task>"
  #
  #     # the block is supposed to 'return' a string which is the
  #     # effective template
  #   end
  #
  # This participant uses
  # "atom-tools" from http://code.necronomicorp.com/trac/atom-tools
  #
  #
  class AtomFeedParticipant
    include MonitorMixin
    include OpenWFE::LocalParticipant
    include OpenWFE::TemplateMixin

    #
    # Made accessible so that blocks may set it.
    #
    attr_accessor :content_type

    def initialize (max_item_count, template=nil, &block)

      super() # very important as this class includes MonitorMixin

      @template = template
      @max_item_count = max_item_count
      @block_template = block

      @feed = Atom::Feed.new("http://localhost")
      @content_type = "xhtml"
    end

    def consume (workitem)

      e = Atom::Entry.new

      e.id = \
        "#{workitem.fei.workflow_instance_id}--" +
        "#{workitem.fei.expression_id}"

      e.title = workitem.atom_entry_title
      e.content = render(workitem)

      e.content["type"] = @content_type

      @feed << e

      @feed = @feed[0, @max_item_count] \
        if @feed.entries.size > @max_item_count

      publish workitem

      reply_to_engine workitem
    end

    protected

      #
      # This base implementation simply calls the eval_template()
      # method of the TemplateMixin.
      # Feel free to override this render() method for custom
      # representations.
      #
      def render (workitem)

        eval_template workitem
      end

      #
      # For the moment, just dumps the feed into a file.
      #
      def publish (workitem)
        synchronize do
          filename = "work/atom_#{workitem.participant_name}.xml"
          f = File.open(filename, "w")
          f << @feed.to_s
          f.close()
        end
      end
  end

end

