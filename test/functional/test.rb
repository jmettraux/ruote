
#
# testing ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

def l(t)

  if ENV['RUOTE_TEST_SPLIT'].to_s == 'true'

    puts
    puts "=== #{t} :"
    puts `ruby -I. #{t} #{ARGV.join(' ')}`

    es = $?.exitstatus
    es = es.nil? ? 66 : es.to_s.to_i

    exit(es) if es != 0

  else

    load(t)
  end
end


unless RUBY_PLATFORM.match(/mswin|mingw/)
  #
  # sorry but no more than 1 worker on windows !
  #
  # so no need to run those 2 workers tests
  #
  Dir.glob(File.join(File.dirname(__FILE__), 'ct_*.rb')).sort.each { |t| l(t) }
    # concurrence/collision tests, tests about 2+ instances of ruote colliding
end

l(File.expand_path('../storage.rb', __FILE__))

Dir.glob(File.join(File.dirname(__FILE__), 'ft_*.rb')).sort.each { |t| l(t) }
  # functional tests targetting features rather than expressions

Dir.glob(File.join(File.dirname(__FILE__), 'rt_*.rb')).sort.each { |t| l(t) }
  # restart tests, start sthing, stop engine, restart, expect thing to resume

Dir.glob(File.join(File.dirname(__FILE__), 'eft_*.rb')).sort.each { |t| l(t) }
  # functional tests targetting specifing expressions

