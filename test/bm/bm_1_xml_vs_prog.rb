
#
# a bit of benchmark
#
# Thu Nov  8 21:48:20 JST 2007
#

require 'benchmark'

require 'openwfe/def'
#require 'openwfe/engine/engine'
require 'openwfe/engine/file_persisted_engine'


class ProgDef < OpenWFE::ProcessDefinition
  sequence do
    toto
    toto
    toto
    toto
    toto
  end
end

xml = <<END
<process-definition name="x" revision="y">
  <sequence>
    <toto/>
    <toto/>
    <toto/>
    <toto/>
    <toto/>
  </sequence>
</process-definition>
END

#$engine = OpenWFE::Engine.new
$engine = OpenWFE::FilePersistedEngine.new

$engine.register_participant "toto" do |workitem|
  # do nothing
end

N = 500

def test (proc_def)
  N.times do
    fei = $engine.launch proc_def
    $engine.wait_for fei
  end
end

Benchmark.bm do |x|
  x.report("prog :") { test ProgDef }
  x.report("xml :") { test xml.strip }
end
