
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

#
# Returns the class of the engine to use, based on the ARGV
#
def determine_engine_class (application_context)

  if ARGV.include?('--help')
    puts %{

ARGUMENTS for functional tests :

  --fs  : used OpenWFE::FsPersistedEngine (fast)
     -y : makes 'fs' store expressions as YAML (slow)

  --tc  : used OpenWFE::TcPersistedEngine (fast)

  --fp  : uses OpenWFE::FilePersistedEngine (slow and deprecated)
  --cfp : uses OpenWFE::CachedFilePersistedEngine (fast and deprecated)

  -C    : disable caching (used for thorough persistence testing)

else uses the in-memory OpenWFE::Engine (fastest, but no persistence at all)

    }
    exit 0
  end

  require 'openwfe/engine'

  application_context[:persist_as_yaml] = true if ARGV.include?('-y')
  application_context[:no_expstorage_cache] = true if ARGV.include?('-C')

  klass = if $ruote_engine_class

    $ruote_engine_class

  else

    if ARGV.include?('--fp') # very slow

      require 'openwfe/engine/file_persisted_engine'
      OpenWFE::FilePersistedEngine

    elsif ARGV.include?('--cfp') # fast but not 100% robust

      require 'openwfe/engine/file_persisted_engine'
      OpenWFE::CachedFilePersistedEngine

    elsif ARGV.include?('--tc') # fast and robust, fastest

      require 'openwfe/engine/tc_engine'
      OpenWFE::TcPersistedEngine

    elsif ARGV.include?('--fs') # fast and robust

      require 'openwfe/engine/fs_engine'
      OpenWFE::FsPersistedEngine

    else # in-memory, use only for testing !

      OpenWFE::Engine
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

