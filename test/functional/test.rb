
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

def l (t)

  if ARGV.include?('--split')

    _v = ARGV.include?('-v') ? ' -v' : ' '

    puts
    puts "=== #{t} :"
    puts `ruby#{_v} #{t}`

    exit $?.exitstatus if $?.exitstatus != 0
  else
    load(t)
  end
end


Dir.glob(File.join(File.dirname(__FILE__), 'ct_*.rb')).sort.each { |t| l(t) }
  # concurrence/collision tests, tests about 2+ instances of ruote colliding

Dir.glob(File.join(File.dirname(__FILE__), 'ft_*.rb')).sort.each { |t| l(t) }
  # functional tests targetting features rather than expressions

Dir.glob(File.join(File.dirname(__FILE__), 'rt_*.rb')).sort.each { |t| l(t) }
  # restart tests, start sthing, stop engine, restart, expect thing to resume

Dir.glob(File.join(File.dirname(__FILE__), 'eft_*.rb')).sort.each { |t| l(t) }
  # functional tests targetting specifing expressions

