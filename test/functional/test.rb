
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

dirpath = File.dirname(__FILE__)

ets = Dir.new(dirpath).entries.select { |e| e.match(/et\_.*\.rb$/) }.sort
  # functional tests targetting specifing expressions

fts = Dir.new(dirpath).entries.select { |e| e.match(/ft\_.*\.rb$/) }.sort
  # functional tests targetting features rather than expressions

(ets + fts).each { |e| load "#{dirpath}/#{e}" }

