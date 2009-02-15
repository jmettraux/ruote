
#
# establishing the activerecord connection for all the tests
#

%w{ lib test }.each do |path|
  path = File.expand_path(File.dirname(__FILE__) + '/../../' + path)
  $:.unshift(path) unless $:.include?(path)
end

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

if "./#{ENV['TEST']}" == __FILE__ or __FILE__ == 'test/extras/active_connection.rb'

  require 'openwfe/extras/participants/active_participants'
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
  bring_down OpenWFE::Extras::ProcessErrorTables
  bring_down OpenWFE::Extras::ExpressionTables
  bring_down OpenWFE::Extras::HistoryTables

  OpenWFE::Extras::WorkitemTables.up
  OpenWFE::Extras::ProcessErrorTables.up
  OpenWFE::Extras::ExpressionTables.up
  OpenWFE::Extras::HistoryTables.up
end

