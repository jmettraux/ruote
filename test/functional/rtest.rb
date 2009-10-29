
#
# firing all the 'restart' tests (rt_)
#

Dir.glob(File.join(File.dirname(__FILE__), 'rt_*.rb')).sort.each { |t| load(t) }
  # restart tests, start sthing, stop engine, restart, expect thing to resume

