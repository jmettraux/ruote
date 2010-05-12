
dashdash = `ruby -v`.match(/^ruby 1\.9\./) ? '' : '--'

puts("\n\n[32m== in memory[0m")
puts
puts `ruby test/unit/storage.rb`
puts("\n[41mFAILED[0m") if $?.exitstatus.to_i != 0

puts("\n\n[32m== fs[0m")
puts
puts `ruby test/unit/storage.rb #{dashdash} --fs`
puts("\n[41mFAILED[0m") if $?.exitstatus.to_i != 0

puts("\n\n[32m== route-couch[0m")
puts
#puts `ruby -r patron -r yajl test/unit/storage.rb #{dashdash} --couch`
puts `ruby test/unit/storage.rb #{dashdash} --couch`
puts("\n[41mFAILED[0m") if $?.exitstatus.to_i != 0

puts("\n\n[32m== route-dm[0m")
puts
#puts `ruby -r yajl test/unit/storage.rb #{dashdash} --dm`
puts `ruby test/unit/storage.rb #{dashdash} --dm`
puts("\n[41mFAILED[0m") if $?.exitstatus.to_i != 0

puts("\n\n[32m== route-redis[0m")
puts
#puts `ruby -r yajl test/unit/storage.rb #{dashdash} --redis`
puts `ruby test/unit/storage.rb #{dashdash} --redis`
puts("\n[41mFAILED[0m") if $?.exitstatus.to_i != 0

puts("\n\n[32m== route-beanstalk[0m")
puts
#puts `ruby -r yajl test/unit/storage.rb #{dashdash} --beanstalk`
puts `ruby test/unit/storage.rb #{dashdash} --beanstalk`
puts("\n[41mFAILED[0m") if $?.exitstatus.to_i != 0

