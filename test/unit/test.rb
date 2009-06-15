
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

dirpath = File.dirname(__FILE__)

uts = Dir.new(dirpath).entries.select { |e| e.match(/^ut\_.*\.rb$/) }.sort
huts = Dir.new(dirpath).entries.select { |e| e.match(/^hut\_.*\.rb$/) }.sort

tests = uts + huts

tests.each { |e| load "#{dirpath}/#{e}" }

#tests.each { |e| puts `ruby #{dirpath}/#{e}` }
  # making sure that each test is runnable standalone

