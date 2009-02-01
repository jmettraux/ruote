
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

#
# Returns the class of the engine to use, based on the ARGV
#
def determine_engine_class (application_context)

  require 'openwfe/engine'

  application_context[:persist_as_yaml] = true if ARGV.include?('-y')

  klass = if $ruote_engine_class

    $ruote_engine_class

  else

    if ARGV.include?('--fp') # very slow

      require 'openwfe/engine/file_persisted_engine'
      OpenWFE::FilePersistedEngine

    elsif ARGV.include?('--cfp') # fast but not 100% robust

      require 'openwfe/engine/file_persisted_engine'
      OpenWFE::CachedFilePersistedEngine

    elsif ARGV.include?('--tp') # fast and robust, fastest

      require 'openwfe/engine/tc_engine'
      OpenWFE::TokyoPersistedEngine

    elsif ARGV.include?('--fs') # fast and robust

      require 'openwfe/engine/fs_engine'
      OpenWFE::FsPersistedEngine

    else # in-memory, use only for testing !

      OpenWFE::Engine
    end
  end

  unless $advertised
    yaml = application_context[:persist_as_yaml] ? ' (yaml)' : ''
    puts
    puts "  using engine of class #{klass}#{yaml}"
    puts
    $advertised = true
  end

  klass
end

