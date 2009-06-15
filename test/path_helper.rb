
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

# making sure the tests see ruote

ruotelib = File.expand_path(File.dirname(__FILE__) + '/../lib')
$:.unshift(ruotelib) unless $:.include?(ruotelib)

