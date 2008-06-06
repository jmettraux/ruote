
require 'rubygems'
require 'openwfe/extras/util/csvtable'

include OpenWFE::Extras

$table = CsvTable.new("http://spreadsheets.google.com/pub?key=pCkopoeZwCNsMWOVeDjR1TQ&output=csv&gid=0")

def decide (hash)

  $table.transform hash

  puts " weather : #{hash['weather']}, month : #{hash['month']}"
  puts "   =>  take umbrella ? #{hash['take_umbrella?']}"
  puts
end

puts

decide({ "weather" => "raining", "month" => "december" })
decide({ "weather" => "sunny", "month" => "december" })
decide({ "weather" => "cloudy", "month" => "may" })

