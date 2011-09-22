
#
# testing ruote
#
# Wed Sep 16 16:28:36 JST 2009
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
#N = 1_000
N = 300

#engine.context[:noisy] = true

Benchmark.benchmark(' ' * 20 + Benchmark::Tms::CAPTION, 20) do |bench|

  bench.report('run') do

    wfid = engine.launch(
      Ruote.process_definition(:name => 'ci') {
        concurrent_iterator(:branches => N.to_s) {
          noop
        }
      }
    )

    engine.logger.wait_for([ [ :processes, :terminated, { :wfid => wfid } ] ])

  end

end

puts

engine.stop

