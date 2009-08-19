
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

Dir.glob(File.join(File.dirname(__FILE__), 'ut_*.rb')).sort.each { |t| load(t) }
Dir.glob(File.join(File.dirname(__FILE__), 'hut_*.rb')).sort.each { |t| load(t) }

