
#
# The Active Record connection for tests.
#
# Running this piece of code standalone will tear down / bring up the
# necessary tables.
#
#     ruby test/ar_test_connection.rb
#

require 'rubygems'

#require_gem 'activerecord'
gem 'activerecord'
require 'active_record'


ActiveRecord::Base.establish_connection(
  :adapter => 'mysql',
  :pool => 30,
  :database => 'test',
  :encoding => 'utf8')
#ActiveRecord::Base.establish_connection(
#  :adapter => 'sqlite3',
#  :dbfile => 'test.db')

if __FILE__ == $0

  $:.unshift('lib')

  require 'openwfe/extras/participants/active_participants'
  require 'openwfe/extras/participants/ar_participants'

  require 'openwfe/extras/expool/db_errorjournal'
  require 'openwfe/extras/expool/db_expstorage'
  require 'openwfe/extras/expool/db_history'

  def bring_down (migration)
    begin
      migration.down
    rescue Exception => e
      puts
      puts "/// failed to bring down  #{migration.name} ///"
      puts
    end
  end

  bring_down OpenWFE::Extras::WorkitemTables
  bring_down OpenWFE::Extras::ArWorkitemTables

  bring_down OpenWFE::Extras::ProcessErrorTables
  bring_down OpenWFE::Extras::ExpressionTables
  bring_down OpenWFE::Extras::HistoryTables


  OpenWFE::Extras::WorkitemTables.up
  OpenWFE::Extras::ArWorkitemTables.up

  OpenWFE::Extras::ProcessErrorTables.up
  OpenWFE::Extras::ExpressionTables.up
  OpenWFE::Extras::HistoryTables.up
end

