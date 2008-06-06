
#
# establishing the activerecord connection for all the tests
#

require 'rubygems'

#require_gem 'activerecord'
gem 'activerecord'
require 'active_record'


ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :database => "test",
  :encoding => "utf8")
#ActiveRecord::Base.establish_connection(
#  :adapter => "sqlite3",
#  :dbfile => "test.db")

if "./#{ENV['TEST']}" == __FILE__

  require 'openwfe/extras/participants/activeparticipants'
  require 'openwfe/extras/expool/dberrorjournal'
  require 'openwfe/extras/expool/dbexpstorage'

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
  bring_down OpenWFE::Extras::ProcessErrorTables
  bring_down OpenWFE::Extras::ExpressionTables

  OpenWFE::Extras::WorkitemTables.up
  OpenWFE::Extras::ProcessErrorTables.up
  OpenWFE::Extras::ExpressionTables.up
end

