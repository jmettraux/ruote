
require 'rubygems'

$:.unshift('~/ruote/lib')
$:.unshift('~/ruote/test')

require 'benchmark'

require 'openwfe/def'
require 'openwfe/engine/file_persisted_engine'
require 'openwfe/extras/engine/db_persisted_engine'

require 'extras/active_connection'


AC = {}
AC[:definition_in_launchitem_allowed] = true

ENGINES = [
  OpenWFE::Engine,
  OpenWFE::FilePersistedEngine,
  OpenWFE::CachedFilePersistedEngine,
  OpenWFE::Extras::DbPersistedEngine,
  OpenWFE::Extras::CachedDbPersistedEngine
]

def do_benchmark (pdef, title)

  puts
  puts title

  Benchmark.benchmark(
    "                               user     system      total       real\n"
  ) do |b|

    ENGINES.each do |engine_class|

      engine = engine_class.new(AC.dup)

      b.report((' ' * 20 + engine_class.to_s)[-25..-1]) do
        fei = engine.launch(pdef)
        engine.wait_for(fei)
      end

      engine.stop
    end
  end
end

#
# system info

puts
puts " ruby : " + `ruby -v`


#
# 40 fields

PDEF0 = OpenWFE.process_definition :name => 't', :revision => 2 do
  sequence do
    40.times do |i|
      set :field => "f#{i}", :value => "val#{i}"
    end
  end
end


#
# 40 vars

PDEF1 = OpenWFE.process_definition :name => 't', :revision => 1 do
  sequence do
    40.times do |i|
      set :var => "v#{i}", :value => "val#{i}"
    end
  end
end

#
# benchmark

do_benchmark(PDEF0, '40 fields')
do_benchmark(PDEF1, '40 vars')

$OWFE_LOG.level = Logger::DEBUG
do_benchmark(PDEF0, '40 fields (debug on)')
do_benchmark(PDEF1, '40 vars (debug on)')
