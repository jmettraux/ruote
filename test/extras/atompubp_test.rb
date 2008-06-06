
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Nov 13 12:47:53 JST 2007
#
# ShinYokohama
#

require 'test/unit'

require 'rubygems'

require 'openwfe/flowexpressionid'
require 'openwfe/workitem'

require 'openwfe/extras/participants/atompub_participants'

require 'rutest_utils'


class AtomPubParticipantTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  def test_0

    target_uri = "https://openwferu.wordpress.com/wp-app.php/posts"

    params = {}
    params[:username] = 'jmettraux'
    params[:password] = ENV['WORDPRESS_PASSWORD']

    params[:categories] = 'openwferu, test'

    app = OpenWFE::Extras::AtomPubParticipant.new target_uri, params

    workitem = OpenWFE::InFlowWorkItem.new
    workitem.fei = new_fei
    workitem.participant_name = "AtomPubParticipant"
    workitem.message = "hello RFC 5023 world !"

    uri = app.consume(workitem)

    puts
    puts uri
    puts
  end

  def test_1

    target_uri = "https://openwferu.wordpress.com/wp-app.php/posts"

    params = {}
    params[:username] = 'jmettraux'
    params[:password] = ENV['WORDPRESS_PASSWORD']

    params[:categories] = 'openwferu, test'

    #params[:title_field] = "title"

    app = OpenWFE::Extras::BlogParticipant.new target_uri, params do
      """
        paragraph 0

        paragraph 1 : ${f:message}

        paragraph 2
      """
    end

    workitem = OpenWFE::InFlowWorkItem.new
    workitem.fei = new_fei
    workitem.participant_name = "AtomPubParticipant"
    workitem.message = "hello RFC 5023 world !"
    workitem.title = "BlogPostParticipant test"

    uri = app.consume(workitem)

    puts
    puts uri
    puts
  end
end

