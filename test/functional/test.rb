
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#


# TODO : rft_ as well...

Dir.glob(File.join(File.dirname(__FILE__), 'ct_*.rb')).sort.each { |t| load(t) }
  # concurrence/collision tests, tests about 2+ instances of ruote colliding

Dir.glob(File.join(File.dirname(__FILE__), 'ft_*.rb')).sort.each { |t| load(t) }
  # functional tests targetting features rather than expressions

Dir.glob(File.join(File.dirname(__FILE__), 'rt_*.rb')).sort.each { |t| load(t) }
  # restart tests, start sthing, stop engine, restart, expect thing to resume

Dir.glob(File.join(File.dirname(__FILE__), 'eft_*.rb')).sort.each { |t| load(t) }
  # functional tests targetting specifing expressions

