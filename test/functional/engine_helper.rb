
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

#
# Returns the class of the engine to use, based on the ARGV
#
def determine_engine_class

  ENV['TOKYO_CABINET_LIB'] = File.expand_path(
    '~/tmp/tokyo-cabinet/libtokyocabinet.dylib'
  ) if ARGV.include?('--tc-latest')

  require 'openwfe/engine'

  if $ruote_engine_class
    $ruote_engine_class
  else
    if ARGV.include?('--fp')
      require 'openwfe/engine/file_persisted_engine'
      OpenWFE::FilePersistedEngine
    elsif ARGV.include?('--cfp')
      require 'openwfe/engine/file_persisted_engine'
      OpenWFE::CachedFilePersistedEngine
    elsif ARGV.include?('--tp')
      require 'openwfe/engine/tc_engine'
      OpenWFE::TokyoPersistedEngine
    else
      OpenWFE::Engine
    end
  end
end

