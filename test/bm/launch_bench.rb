
# a ruote launch benchmark, as discussed with @hassox
# http://ruote.rubyforge.org/irclogs/ruote_2010-10-20.txt

puts
puts RUBY_VERSION
puts

require 'rubygems'
require 'benchmark'
require 'fileutils'
require 'ruote' # gem install ruote
require 'ruote/storage/fs_storage'

FileUtils.rm_rf('bench')

engine = Ruote::Engine.new(Ruote::FsStorage.new('bench'))

pdef = Ruote.process_definition do
  alpha :task => 'walk the dog'
  alpha :task => 'walk the dog'
  alpha :task => 'walk the dog'
  alpha :task => 'walk the dog'
  alpha :task => 'walk the dog'
  alpha :task => 'walk the dog'
  alpha :task => 'walk the dog'
  alpha :task => 'walk the dog'
  alpha :task => 'walk the dog'
  alpha :task => 'walk the dog'
end

Benchmark.benchmark(' ' * 31 + Benchmark::Tms::CAPTION, 31) do |b|
  b.report('1000 launches') do
    1000.times { engine.launch(pdef) }
  end
end

