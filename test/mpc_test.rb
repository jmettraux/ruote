
#
# multi process concurrence test
#

t = Time.now

N = 100
failures = 0

N.times do |i|

  #o = `ruby19 test/functional/ct_0_concurrence.rb -n test_collision --dm`
  o = `ruby19 test/functional/ct_0_concurrence.rb -n test_collision #{ARGV[0]}`

  if $?.exitstatus == 0
    print '.'
    puts(o) if i == 0
  else
    failures += 1
    print 'x'
    puts; puts(o)
  end
  STDOUT.flush
end

puts
puts "failures : #{failures}/#{N}  #{(Time.now - t).to_f} seconds"

