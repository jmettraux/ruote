
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

#require 'profile'

require 'benchmark'
require 'rubygems'

require File.dirname(__FILE__) + '/../path_helper'
require File.dirname(__FILE__) + '/../functional/engine_helper'

ac = {
  #:definition_in_launchitem_allowed => true
}

engine = determine_engine_class(ac).new(ac)

#puts
#p engine.class
#puts

#N = 10_000
N = 1_000
#N = 100

$count = 0

engine.register_participant("count") do |workitem|
  $count += 1
  #print '.'
end

Benchmark.benchmark(' ' * 20 + Benchmark::Tms::CAPTION, 20) do |bench|

  bench.report('run') do
    wfid = engine.launch(
      Ruote.process_definition(:name => 'bm26c') {
        sequence do
          N.times do
            #count
            participant :ref => 'count'
          end
        end
      }#, :wait_for => true)
    )
    engine.logger.wait_for([ [ :processes, :terminated, { :wfid => wfid } ] ])
  end

end

puts

engine.stop

# N = 100

# Sat Jan 24 23:57:09 JST 2009
# ruby 1.8.6 (2008-03-03 patchlevel 114) [universal-darwin9.0]
#
# OpenWFE::Engine
#     user     system      total       real
#   0.130000   0.010000   0.140000 (  0.161848)
# jmettraux:ruote[test_redux]/$ ruby test/bm/load_26c.rb --fp
#
# OpenWFE::FilePersistedEngine
#     user     system      total       real
#   3.950000   0.220000   4.170000 (  4.810950)
# jmettraux:ruote[test_redux]/$ ruby test/bm/load_26c.rb --cfp
#
# OpenWFE::CachedFilePersistedEngine
#     user     system      total       real
#   0.390000   0.030000   0.420000 (  0.481701)
# jmettraux:ruote[test_redux]/$ ruby test/bm/load_26c.rb --tp
#
# OpenWFE::TokyoPersistedEngine (Tokyo Cabinet version 1.3.9 (503:1.0))
#     user     system      total       real
#   3.160000   0.060000   3.220000 (  3.749696)

# Mon May 18 13:50:49 JST 2009
# ruby 1.9.1p129 (2009-05-12 revision 23412) [i386-darwin9.6.0]
#
#  using engine of class Ruote::Engine
#
#     user     system      total        real
#   0.010000   0.000000   0.010000 (  0.010206)
#
# No participant/subprocess lookup...

