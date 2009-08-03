
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Aug  3 17:17:13 JST 2009
#

require 'benchmark'
require 'rubygems'

require File.dirname(__FILE__) + '/../path_helper'
require File.dirname(__FILE__) + '/../functional/engine_helper'

require 'ruote/log/test_logger'
require 'ruote/part/hash_participant'

N = 1000
#N = 100

ac = {
  #:definition_in_launchitem_allowed => true
}

engine = determine_engine_class(ac).new(ac)

pdef = Ruote.process_definition :name => 'test' do
  alpha
end

engine.register_participant :alpha, Ruote::HashParticipant

Benchmark.benchmark(' ' * 31 + Benchmark::Tms::CAPTION, 31) do |b|

  wfid = nil

  b.report("launch #{N} processes") do
    N.times { wfid = engine.launch(pdef) }
  end

  sleep 3

  b.report("listing 1 process") do
    engine.process(wfid)
  end
  b.report("listing #{N} processes") do
    ps = engine.processes
    p [ :wrong, ps.size ] if ps.size != N
  end
end

#engine.shutdown

