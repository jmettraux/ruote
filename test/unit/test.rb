
#
# testing ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

load File.join(File.dirname(__FILE__), 'storage.rb')

Dir.glob(File.join(File.dirname(__FILE__), 'ut_*.rb')).sort.each { |t| load(t) }
Dir.glob(File.join(File.dirname(__FILE__), 'hut_*.rb')).sort.each { |t| load(t) }

