
dashdash = ''
dashdash = '--' unless `ruby -v`.match(/^ruby 1\.9\./)

puts "\n\n\n== in memory"
puts
puts `ruby test/unit/storage.rb`

puts "\n\n\n== fs"
puts
puts `ruby test/unit/storage.rb #{dashdash} --fs`

puts "\n\n\n== ruote-couch"
puts
#puts `ruby -r patron -r yajl test/unit/storage.rb #{dashdash} --couch`
puts `ruby test/unit/storage.rb #{dashdash} --couch`

puts "\n\n\n== ruote-dm"
puts
#puts `ruby -r yajl test/unit/storage.rb #{dashdash} --dm`
puts `ruby test/unit/storage.rb #{dashdash} --dm`

puts "\n\n\n== ruote-redis"
puts
#puts `ruby -r yajl test/unit/storage.rb #{dashdash} --redis`
puts `ruby test/unit/storage.rb #{dashdash} --redis`

puts "\n\n\n== ruote-beanstalk"
puts
#puts `ruby -r yajl test/unit/storage.rb #{dashdash} --beanstalk`
puts `ruby test/unit/storage.rb #{dashdash} --beanstalk`

