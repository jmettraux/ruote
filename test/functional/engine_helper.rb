
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

require 'ruote/storage/hash_storage'
require 'ruote/storage/fs_storage'


#
# Returns the class of the engine to use, based on the ARGV
#
def determine_storage

  if ARGV.include?('--help')
    puts %{

ARGUMENTS for functional tests :

  --fs  : uses Ruote::FsStorage

else uses the in-memory Ruote::Engine (fastest, but no persistence at all)

    }
    exit 0
  end

  if ARGV.include?('--fs')
    Ruote::FsStorage.new('work')
  else
    Ruote::HashStorage.new
  end
end

