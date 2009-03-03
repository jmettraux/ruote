#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# the software.
#
# Made in Japan.
#++


$:.unshift('lib')


require 'rubygems'
require 'openwfe/expool/wfidgen'
require 'openwfe/expool/fs_expstorage'
require 'openwfe/expressions/expression_map'

#
# a tool for converting persisted process instances from one format to the
# other.
#

USAGE = %{
  = ruby #{File.dirname(__FILE__)} [opts] {source} {target}
  
  pooltool.rb migrates an expression pool (Ruote persistence) from one
  format to the other.

  == examples

  to copy from the dir expool to expool2, making sure that the target uses
  YAML for serialization :

    ruby work/pooltool.ru -y work/expool work/expool2

  to migrate from the dir expool to a TokyoCabinet file (.tct mandatory) :

    ruby work/pooltool.ru work/expool work/expool.tct

  to migrate from a Tokyo Tyrant to a directory :

    ruby work/pooltool.ru localhost:1978 work/expool2

  to migrate from a Tokyo Tyrant (unix socket) to a directory (YAML
  serialization set to ON) :

    ruby work/pooltool.ru -y /var/tyrant_socket:0 work/expool2

  to migrate from a database to a directory (yaml) :

    ruby work/pooltool.ru \\
    -y \\
    adapter=mysql:database=rw2_development:username=u:password=p \\
    work/expool2

  to migrate from a DataMapper storage to a file one (notice the "dm:" prefix
  and the DataMapper URL) :

    ruby work/pooltool.ru -y dm:mysql://localhost/rw2_production work/expool2

  it's possible to migrate to/from a single .yaml file :

    ruby work/pooltool.ru work/expool/ dump.yaml


  Warning : if the source is an ActiveRecord based storage, then the target 
            must be of another type, and vice versa.
            No such worries with DataMapper.

  
  == options

  -v, --version   : print the version of itog.rb and exits
  -h, --help      : print this help text and exits

  -y, --yaml      : states that the target should be serialized with YAML
                    (only works if the target is a directory)
  -o, --overwrite : overwrites the target. If there are already expressions in
                    the target, they are by default, not overwritten. With this
                    switch, they will get overwritten.

  == specifying the source and the target

  the format is {dir/file/ar/host:port}
}

#
# parsing options

rest = ARGV.select { |e| !e.match(/^-/)  }[-2, 2] || []

opts = (ARGV - rest).inject([]) { |a, e|
  t, v = e[0, 1] == '-' ? [ a, [ e ] ] : [ a.last, e ]; t << v; a
}.inject({}) { |h, (k, v)|
  h[k] = v || true; h
}

if rest.size < 2
  puts
  puts "  ** missing {source} and/or {target}"
  puts
  p [ opts, rest ]
  puts
  puts
  puts USAGE
  exit(1)
end

if opts['--help'] or opts['-h']
  puts USAGE
  exit(0)
end

if opts['--version'] or opts['-v']
  puts '0.0.1'
  exit(0)
end

#
# dump.yaml storage

class YamlDump
  def initialize (path)
    @path = path
  end
  def [] (fei)
    nil
  end
  def []= (fei, fexp)
    dump.write(fexp.to_yaml)
  end
  def each
    return unless block_given?
    File.open(@path, 'r') do |f|
      YAML.load_documents(f) { |fexp| yield(fexp.fei, fexp) }
    end
  end
  def close
    return unless @dump
    @dump.close
    @dump = nil
  end
  protected
  def dump
    @dump ||= File.open(@path, 'w')
  end
end

#
# database / ORM connection methods

def ar_connect (ac, s)

  require 'openwfe/extras/expool/ar_expstorage'

  options = s.split(':').inject({}) { |h, pair|
    ss = pair.split('='); h[ss[0]] = ss[1]; h
  }

  ActiveRecord::Base.establish_connection(options)
end

def dm_connect (ac, s)

  require 'openwfe/extras/expool/dm_expstorage'

  repo = "repo#{s.hash}".to_sym
  ac[:expstorage_dm_repository] = repo

  DataMapper.setup(repo, s)
end

#
# conf methods

def determine_source_suffix (dir)

  Dir["#{dir}/**/*.ruote"].size > Dir["#{dir}/**/*.yaml"].size ?
    'ruote' : 'yaml'
end

def determine_storage (s, opts, target=false)

  ac = {}

  ac[:s_wfid_generator] =
    OpenWFE::KotobaWfidGenerator.new(:s_wfid_generator, ac)

  sto =  if s.match(/^dm:/)

    dm_connect(ac, s[3..-1])
    OpenWFE::Extras::DmExpressionStorage.new('storage', ac)

  elsif s.index('=') # active record

    ar_connect(ac, s)
    OpenWFE::Extras::ArExpressionStorage.new('storage', ac)

  elsif s.index(':') # tokyo tyrant

    require 'openwfe/expool/tt_expstorage'
    ss = s.split(':')
    ac[:tyrant_expstorage_host] = ss.first
    ac[:tyrant_expstorage_port] = ss.last.to_i
    OpenWFE::TtExpressionStorage.new('storage', ac)

  elsif s.match(/\.yaml$/) # dump.yaml

    require 'yaml'
    YamlDump.new(s)

  elsif s.match(/\.tct$/) # tokyo cabinet

    require 'openwfe/expool/tc_expstorage'
    ac[:expstorage_path] = s
    OpenWFE::TcExpressionStorage.new('storage', ac)

  else # it's a dir

    ac[:expstorage_path] = s
    OpenWFE::FsExpressionStorage.new('storage', ac)

  end

  if ( ! target) and sto.respond_to?(:suffix=)
    sto.suffix = determine_source_suffix(s)
  end

  if (target and
    (opts['-y'] or opts['--yaml']) and
    sto.respond_to?(:persist_as_yaml=)
  )
    sto.persist_as_yaml = true
  end

  sto
end

overwrite = opts['-o'] || opts['--overwrite']

#
# let's do the job

source = rest[0]
target = rest[1]

puts
puts "  source : #{source}"
puts "  target : #{target}"
puts
puts "  opts : #{opts.inspect}"
puts

source = determine_storage(source, opts)
target = determine_storage(target, opts, true)

i = 0
o = 0
s = 0
processes = {}

source.each do |fei, fexp|

  label = "#{fei.wfid} #{fei.expid} #{fei.expname}  (#{fexp.class})"

  if target[fei]
    if overwrite
      i += 1
      o += 1
      processes[fei.parent_wfid] = true
      puts "    o #{label}"
      target[fei] = fexp
    else
      s += 1
      puts "    S #{label}"
    end
  else
    i += 1
    processes[fei.parent_wfid] = true
    puts "    . #{label}"
    target[fei] = fexp
  end
end

source.close
target.close

processes.delete('0')
  # not counting the lonely engine env as a process instance

puts
puts "  migrated #{i} expressions (skipped #{s} / overwrote #{o})."
puts "  migrated #{processes.size} processes."
puts

