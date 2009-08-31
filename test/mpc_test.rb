
#
# multi process concurrence test
#

t = Time.now

N = 100
failures = 0

N.times do
  #o = `ruby19 test/functional/ct_0_concurrence.rb -n test_collision --dm`
  o = `ruby19 test/functional/ct_0_concurrence.rb -n test_collision`
  if $?.exitstatus == 0
    print '.'
  else
    failures += 1
    print 'x'
    puts; puts(o)
  end
  STDOUT.flush
end

puts
puts "failures : #{failures}/#{N}  #{(Time.now - t).to_f} seconds"

