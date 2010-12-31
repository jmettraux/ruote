
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

require 'ruote/storage/hash_storage'
require 'ruote/storage/fs_storage'


def locate_storage_impl (arg)

  pers = arg[2..-1]

  path = Dir[File.expand_path(
    File.join(File.dirname(__FILE__), %w[ .. .. .. ], "ruote-#{pers}*"))].first

  File.directory?(path) ? [ pers, path ] : nil
end

#
# Returns the class of the engine to use, based on the ARGV
#
def determine_storage (opts)

  if ARGV.include?('--help')
    puts %{

ARGUMENTS for functional tests :

  --fs  : uses Ruote::FsStorage

else uses the in-memory Ruote::Engine (fastest, but no persistence at all)

    }
    exit 0
  end

  ps = ARGV.select { |a| a.match(/^--/) }
  ps.delete('--split')

  persistent = opts.delete(:persistent)

  if ps.include?('--fs')

    begin
      require 'yajl'
    rescue LoadError
      require 'json'
    end
    Rufus::Json.detect_backend

    Ruote::FsStorage.new('work', opts)

  elsif not ps.empty?

    pers = nil
    ps.find { |a| pers = locate_storage_impl(a) }

    raise "no persistence found (#{ps.inspect})" unless pers

    lib, path = pers
    $:.unshift(File.join(path, 'lib'))

    begin
      load 'test/functional_connection.rb'
    rescue LoadError => le
      begin
        load File.join(path, %w[ test functional_connection.rb ])
      rescue LoadError => lee
        begin
          load File.join(path, %w[ test integration_connection.rb ])
        rescue LoadError => leee
          p le
          p lee
          p leee
          raise leee
        end
      end
    end

    new_storage(opts)

  elsif persistent

    begin
      require 'yajl'
    rescue LoadError
      require 'json'
    end
    Rufus::Json.detect_backend

    Ruote::FsStorage.new('work', opts)

  else

    Ruote::HashStorage.new(opts)
  end
end

