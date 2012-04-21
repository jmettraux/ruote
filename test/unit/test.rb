
#
# testing ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

def l(t)

  if ARGV.include?('--split')

    _v = ARGV.include?('-v') ? ' -v' : ' '

    puts
    puts "=== #{t} :"
    puts `ruby#{_v} #{t} #{ARGV.join(' ')}`

    exit $?.exitstatus if $?.exitstatus != 0
  else
    load(t)
  end
end

Dir.glob(File.join(File.dirname(__FILE__), 'ut_*.rb')).sort.each { |t| l(t) }

