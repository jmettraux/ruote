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

require 'yaml'
require 'openwfe/rexml'

require 'openwfe/participants/participants'

require 'atom/entry' # gem 'atom-tools'
require 'atom/collection'


module OpenWFE::Extras

  #
  # This participants posts (as in HTTP POST) a workitem
  # to an AtomPub enabled resource.
  #
  #   target_uri = "https://openwferu.wordpress.com/wp-app.php/posts"
  #
  #   params = {}
  #   params[:username] = 'jmettraux'
  #   params[:password] = ENV['WORDPRESS_PASSWORD']
  #   params[:categories] = 'openwferu, test'
  #
  #   engine.register_participant(
  #     "app", OpenWFE::Extras::AtomPubParticipant.new target_uri, params)
  #
  # This base implementation dumps workitem as YAML in the entry content.
  #
  # See BlogParticipant for a human-oriented blog posting participant.
  #
  class AtomPubParticipant
    include OpenWFE::LocalParticipant

    #
    # The URI to post to
    #
    attr_accessor :target_uri

    attr_accessor :author_name, :author_uri


    def initialize (target_uri, params)

      @target_uri = target_uri

      @username = params[:username]
      @password = params[:password]

      @author_name = \
        params[:author_name] || self.class.name
      @author_uri = \
        params[:author_uri] || "http://openwferu.rubyforge.org"


      @categories = params[:categories] || []
      @categories = @categories.split(",") if @categories.is_a?(String)
      @categories = Array(@categories)
    end

    #
    # The incoming workitem will generate an atom entry that will
    # get posted to the target URI.
    #
    # This consume() method returns the URI (as a String) where the
    # just uploaded post can be edited.
    #
    def consume (workitem)

      entry = Atom::Entry.new
      entry.updated! # set updated time to now

      render_author entry, workitem
      render_categories entry, workitem
      render_content entry, workitem

      h = Atom::HTTP.new
      h.user = @username
      h.pass = @password
      h.always_auth = :basic

      res = Atom::Collection.new(@target_uri, h).post!(entry)

      # initial implementation
      # don't catch an error, let the process fail

      #res.read_body
      extract_new_link res
    end

    protected

      #
      # This base implementation simply uses a YAML dump of the workitem
      # as the post content (with a content type of 'html').
      #
      def render_content (entry, workitem)

        entry.title = \
          workitem.participant_name + " " +
          workitem.fei.expression_id + " " +
          workitem.fei.workflow_instance_id

        entry.content = workitem.to_yaml
        entry.content["type"] = "html"
      end

      #
      # This default implementation simply builds a single author
      # out of the :author_name, :author_uri passed as initialization
      # params.
      #
      def render_author (entry, workitem)

        author = Atom::Author.new
        author.name = author_name
        author.uri = author_uri

        entry.authors << author
      end

      #
      # This base implementations simply adds the categories listed
      # in the :categories initialization parameter.
      # The target_uri is used as the scheme for the categories.
      #
      # You can override this method to add extra categories or to
      # have completely different categories.
      #
      def render_categories (entry, workitem)

        @categories.each do |s|

          c = Atom::Category.new

          c["scheme"] = @target_uri
          c["term"] = s.strip

          entry.categories << c
        end
      end

      #
      # Extracts the link of the newly created resource (newly posted blog
      # entry), and returns it as a String.
      #
      def extract_new_link (response)

        doc = REXML::Document.new response.read_body

        #REXML::XPath.first(doc.root, "//link[@rel='edit']")
          #
          # doesn't work :(

        REXML::XPath.first(doc.root, "//link[2]").attribute('href')
          #
          # will break if the order changes :(
      end
  end

  #
  # A participant that blogs.
  #
  #  require 'openwfe/extras/participants/atompub_participants'
  #  include OpenWFE::Extras
  #
  #  target_uri = "https://openwferu.wordpress.com/wp-app.php/posts"
  #
  #  params = {}
  #  params[:username] = 'jeff'
  #  params[:password] = 'whatever'
  #
  #  params[:categories] = 'openwferu, test'
  #
  #  #params[:title_field] = "title"
  #    #
  #    # which workitem field will hold the post title ?
  #    # by default, it's "title"
  #
  #  engine.register_participant "blogger", BlogParticipant.new(target_uri, params) do
  #    """
  #      paragraph 0
  #
  #      paragraph 1 : ${f:message}
  #
  #      paragraph 2
  #    """
  #  end
  #
  # This participant takes its template and the workitem it receives to
  # publish a blog entry.
  #
  # The template can be specified as a block (as in the previous example)
  # or via the :template parameter.
  #
  class BlogParticipant < AtomPubParticipant
    include OpenWFE::TemplateMixin

    def initialize (target_uri, params, &block)

      super

      @template = params[:template]
      @block_template = block

      @content_type = params[:content_type] || "html"

      @title_field = params[:title_field] || "title"
    end

    protected

      def render_content (entry, workitem)

        entry.title = workitem.attributes[@title_field].to_s

        entry.content = eval_template workitem
        entry.content["type"] = @content_type
      end
  end
end

