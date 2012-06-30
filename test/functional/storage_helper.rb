
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

require 'ruote/storage/hash_storage'


def locate_storage_impl(pers)

  glob = File.expand_path("../../../../ruote-#{pers}*", __FILE__)

  path = Dir[glob].first

  if path
    File.directory?(path) ? [ pers, path ] : nil
  elsif glob.split('/').include?('bundler')
    glob.match(/^(.+\/ruote-#{pers}\/).+/) ? [ pers, $~[1] ] : nil
  end
end

# Returns an instance of the storage to use (the ARGV determines which
# storage to use).
#
def determine_storage(opts)

  if ARGV.include?('--help')
    puts %{

ARGUMENTS for functional tests :

  --fs  : uses Ruote::FsStorage

else uses the in-memory Ruote::Engine (fastest, but no persistence at all)

    }
    exit 0
  end

  ps = ARGV.select { |a| a.match(/^--[a-z]/) }
  ps.delete('--split')
  ps = ps.collect { |s| m = s.match(/^--(.+)$/); m ? m[1] : s }

  ps = [ ENV['RUOTE_STORAGE'] ].compact if ps.empty?

  ps = [] if ps == [ 'hash' ] || ps == [ 'memory' ]

  persistent = opts.delete(:persistent)

  if ps.include?('fs')

    require 'ruote/storage/fs_storage'

    require_json
    Rufus::Json.detect_backend

    Ruote::FsStorage.new('work', opts)

  elsif not ps.empty?

    pers = ps.inject(nil) { |r, a| r ? r : locate_storage_impl(a) }

    raise "no persistence found (#{ps.inspect})" unless pers

    lib, path = pers
    $:.unshift(File.join(path, 'lib'))

    load_errors = []

    [ '.', path ].product(%w[
      connection functional_connection integration_connection
    ]).each do |pa, f|

      paf = "#{File.join(pa, 'test', f)}.rb"
      begin
        load(paf)
        load_errors = nil
        break
      rescue LoadError => le
        load_errors << [ paf, le ]
      end
    end

    if load_errors
      puts "=" * 80
      puts "** failed to load connection"
      load_errors.each do |paf, le|
        puts
        puts paf
        p le
      end
      puts "=" * 80
      exit(1)
    end

    new_storage(opts)

  elsif persistent

    require_json
    Rufus::Json.detect_backend

    require 'ruote/storage/fs_storage'

    Ruote::FsStorage.new('work', opts)

  else

    Ruote::HashStorage.new(opts)
  end
end

