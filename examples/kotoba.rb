
require 'pp'
require 'rubygems'
require 'openwfe/util/kotoba'

3.times do

  i = (rand * 1000000).to_i
  s = Kotoba::from_integer i

  puts "#{i} => #{s}"
  puts "#{s} => #{Kotoba::to_integer(s)}"
    # forth and back

  a = Kotoba::split s

  print "#{s} => "; pp a
    # showing how the 'word' is split

  puts "."
end

