
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

require 'ruote/engine'


if ARGV.include?('--em')
  puts
  puts 'starting EM'
  puts

  require 'eventmachine'

  unless (EM.reactor_running?)

    Thread.new { EM.run { } }

    #sleep 0.200
    #while (not EM.reactor_running?)
    #  Thread.pass
    #end
    #  #
    #  # all this waiting, especially for the JRuby eventmachine, which seems
    #  # rather 'diesel'
  end
end

#
# Returns the class of the engine to use, based on the ARGV
#
def determine_engine_class (application_context)

  if ARGV.include?('--help')
    puts %{

ARGUMENTS for functional tests :

  --em  : starts EventMachine, lets Ruote use the EM based workqueue

  --fs  : uses Ruote::FsPersistedEngine (fast)
     -y : makes 'fs' store expressions as YAML (slow)

  -C    : disable caching (used for thorough persistence testing)

else uses the in-memory Ruote::Engine (fastest, but no persistence at all)

    }
    exit 0
  end

  application_context[:persist_as_yaml] = ARGV.include?('-y')
  application_context[:no_expstorage_cache] = ARGV.include?('-C')

  klass = $ruote_engine_class

  klass ||= $ruote_engines.find { |k, v| ARGV.include?("--#{k}") }

  if klass.is_a?(Array) and klass[1].is_a?(Class)

    klass = klass[1]

  elsif klass.is_a?(Array)

    prefix, v = klass
    path, libpath, lib = v

    $:.unshift(File.join(libpath, 'lib'))

    require(File.join(libpath, 'test', 'connection'))
    require(path)

    klass =
      eval("Ruote::#{lib.capitalize}::#{prefix.capitalize}PersistedEngine")
  end

  klass ||= Ruote::Engine

  unless $advertised

    yaml = application_context[:persist_as_yaml] ? ' (yaml)' : ''
    cache = application_context[:no_expstorage_cache] ? ' (no cache)' : ''

    puts
    puts "  using engine of class #{klass}#{yaml}#{cache}"
    puts

    $advertised = true
  end

  klass
end

#
# detect persistence alternatives

ruote_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
ruote_parent_dir = File.expand_path(File.join(ruote_dir, '..'))

ruotes = Dir.new(ruote_parent_dir).entries.select { |fn| fn.match(/^ruote-/) }

$ruote_engines = ruotes.inject({}) do |h, dir|

  path = File.join(ruote_parent_dir, dir)
  lib = dir.match(/^ruote-(.+)$/)[1]
  Dir.glob(File.join(path, 'lib', '**', '*_engine.rb')).each do |epath|
    prefix = epath.match(/([^\/\_]+)_engine.rb$/)[1]
    h[prefix] = [ epath, path, lib ]
  end

  h
end

$ruote_engines['fs'] = Ruote::FsPersistedEngine

#p $ruote_engines

