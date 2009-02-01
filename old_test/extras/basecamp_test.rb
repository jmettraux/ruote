
#
# testing the basecamp participants
#
# Wed Feb  6 16:24:12 JST 2008
#

require 'test/unit'

require 'openwfe/extras/participants/basecamp_participants'


class BasecampTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  #class StubWorkitem
  #  attr_accessor :attributes
  #  def initialize atts
  #    @attributes = atts
  #  end
  #end

  def test_0

    p = OpenWFE::Extras::BasecampParticipant.new(
      :host => ENV['BC_HOST'],
      :username => ENV['BC_USERNAME'],
      :password => ENV['BC_PASSWORD'],
      #:project_id => ENV['BC_PROJECT_ID'],
      :todo_list_id => ENV['BC_TODO_LIST_ID'],
      :responsible_party_id => ENV['BC_RESPONSIBLE_PARTY_ID'],
      :ssl => false)

    class << p
      def reply_to_engine workitem
        # nada
      end
    end

    workitem = {}
    workitem['todo_text'] = "this is a test (#{Time.now})"

    p.consume workitem

    assert_not_nil workitem['todo_id']
  end
end

