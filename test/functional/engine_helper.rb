
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

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

  require 'ruote/engine'

  application_context[:persist_as_yaml] = true if ARGV.include?('-y')
  application_context[:no_expstorage_cache] = true if ARGV.include?('-C')

  klass = if $ruote_engine_class

    $ruote_engine_class

  else

    if ARGV.include?('--fs') # fast and robust

      require 'ruote/engine/fs_engine'
      Ruote::FsPersistedEngine

    else # in-memory, use only for testing !

      Ruote::Engine
    end
  end

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

