
puts "\n\n\n== in memory"
puts
puts `ruby test/unit/storage.rb`

puts "\n\n\n== fs_storage"
puts
puts `ruby test/unit/storage.rb --fs`

puts "\n\n\n== couch_storage"
puts
puts `ruby -r patron -r yajl test/unit/storage.rb --couch`

puts "\n\n\n== dm_storage"
puts
puts `ruby -r yajl test/unit/storage.rb --dm`

