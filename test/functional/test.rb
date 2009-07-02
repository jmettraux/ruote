
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

dirpath = File.dirname(__FILE__)

# TODO : rft_ as well...

efts = Dir.new(dirpath).entries.select { |e| e.match(/^eft\_.*\.rb$/) }.sort
  # functional tests targetting specifing expressions

fts = Dir.new(dirpath).entries.select { |e| e.match(/^ft\_.*\.rb$/) }.sort
  # functional tests targetting features rather than expressions

rts = Dir.new(dirpath).entries.select { |e| e.match(/^rt\_.*\.rb$/) }.sort
  # restart tests, start sthing, stop engine, restart, expect thing to resume

tests = efts + fts + rts

tests.each { |e| load(File.join(dirpath, e)) }

#tests.each { |e| puts `ruby #{dirpath}/#{e}` }
  # making sure that each test is runnable standalone

