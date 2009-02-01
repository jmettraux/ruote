
#
# NUT = not a unit test
# some kind of a manual test
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/util/irb'
require 'openwfe/engine/engine'


engine = OpenWFE::Engine.new

OpenWFE::trap_int_irb(binding())

sleep(20)

