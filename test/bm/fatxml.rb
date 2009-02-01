
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Jan 25 14:42:07 JST 2009
#

require 'rubygems'
require 'benchmark'

require File.dirname(__FILE__) + '/../path_helper'
require File.dirname(__FILE__) + '/../functional/engine_helper'

require 'openwfe/participants'


def generate_xml (lines)
  xml = "<process-definition name='test' revision='0'>\n"
  40.times { |i| xml << "<set field='field#{i}' value='value#{i}' />\n" }
  xml << "<sequence>\n"
  lines.times { |i| xml << "<participant ref='alpha' activity='nothing' />\n" }
  xml << "</sequence>\n"
  xml << "</process-definition>\n"
  xml
end

class SinkParticipant
  include OpenWFE::LocalParticipant
  def initialize (&block)
    @block = block
  end
  def consume (workitem)
    @block.call(workitem)
  end
end

ac = {
  :definition_in_launchitem_allowed => true
}

engine = determine_engine_class(ac).new(ac)


Benchmark.benchmark(' ' * 20 + Benchmark::Tms::CAPTION, 20) do |bench|

  bench.report('fat xml test') do

    t = Thread.current

    engine.register_participant(
      :alpha,
      SinkParticipant.new() {
        #p :wakeup
        t.wakeup
      })

    xml = generate_xml(1170)

    engine.launch(xml)

    Thread.stop
  end

end

puts


