
a = "A"
b = 2

require 'openwfe/util/irb'

OpenWFE::trap_int_irb(binding())

sleep(30)

puts "out"

