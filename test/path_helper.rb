
#
# testing ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

# making sure the tests see ruote

puts `ruby -v`
puts Time.now.to_s

ruotelib = File.expand_path('../../lib', __FILE__)
$:.unshift(ruotelib) unless $:.include?(ruotelib)

