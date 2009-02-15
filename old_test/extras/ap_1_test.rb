
require 'test/unit'

require File.dirname(__FILE__) + '/ap_test_base'

require 'openwfe/extras/participants/active_participants'


class Active1Test < Test::Unit::TestCase
  include ApTestBase

  def setup

    OpenWFE::Extras::Workitem.destroy_all
      # let's make sure there are no workitems left
  end

  def teardown

    OpenWFE::Extras::Workitem.destroy_all
  end

  #
  # tests

  def test_0

    wi = new_wi('participant alpha')

    threads = (1..100).to_a.inject([]) do |a, i|
      a << Thread.new do

        sleep rand()

        f = OpenWFE::Extras::Field.new_field("some_field_#{i}", "val_#{i}")

        wi.fields << f

        #print "\n/// added #{f.id} #{f.fkey}, #{f.svalue}"
      end
      a
    end
    threads.each { |t| t.join }

    wi.save!

    assert_equal 100, wi.fields.size
  end

  #
  # monkey patching Active Record 2.2.2 to prevent
  #
  # exception : You have a nil object when you didn't expect it!
  # You might have expected an instance of Array.
  # The error occurred while evaluating nil.-
  # ./vendor/rails/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb:159:in `decrement_open_transactions'
  # ,/vendor/rails/activerecord/lib/active_record/transactions.rb:131:in `transaction'
  # ./vendor/rails/activerecord/lib/active_record/associations/association_collection.rb:136:in `transaction'
  # ./vendor/rails/activerecord/lib/active_record/associations/association_collection.rb:111:in `<<'
  # ./vendor/openwfe/extras/participants/activeparticipants.rb:224:in `from_owfe_workitem'
  #
  class ActiveRecord::ConnectionAdapters::AbstractAdapter

    # original :
    #
    #def decrement_open_transactions
    #  @open_transactions -= 1
    #end

    def decrement_open_transactions
      @open_transactions && @open_transactions -= 1
    end
  end

  def test_1

    fields = { 'alpha' => '0', 'bravo' => 2, 'charly' => :two }

    threads = (1..50).to_a.inject([]) do |a, i|
      a << Thread.new do
        sleep rand()
        wi = new_wi "participant_#{i}"

        wi.save!
        #wi.save! rescue nil
      end
      a
    end
    threads.each { |t| t.join }

    assert_equal 50, OpenWFE::Extras::Workitem.find(:all).size
  end

end

