
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest45b < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  DEF0 = <<-EOS
<process-definition name="bug_20307" revision="0">
  <concurrent-iterator on-value="1, 2, 3" to-field="x">
  <sequence>
    <sequence>
    <participant ref="alpha" />
    <if test="${f:stop_here}" >
      <cancel-process />
    </if>
    </sequence>
    <participant ref="bravo" />
  </sequence>
  </concurrent-iterator>
</process-definition>
  EOS

  def test_0

    @engine.register_participant :alpha do |wi|
      #p [ :alpha, wi.fei.to_short_s ]
      @tracer << "alpha\n"
    end
    @engine.register_participant :bravo do |wi|
      #p [ :bravo, wi.fei.to_short_s ]
      @tracer << "bravo\n"
    end

    dotest DEF0, ([ 'alpha' ] * 3 + [ 'bravo' ] * 3).join("\n")
  end

  def test_1

    log_level_to_debug

    @engine.register_participant :alpha do |wi|
      @tracer << "alpha\n"
      if wi.x == "2"
        wi.stop_here = true
        @tracer << "stop\n"
      end
    end
    @engine.register_participant :bravo do |wi|
      @tracer << "bravo\n"
    end

    @engine.launch DEF0
      # cannot use dotest() as it waits for the 'terminate'
      # signal which is not emitted when a process gets cancelled

    sleep 0.400
    sleep 0.400 # when running with D

    assert_equal %w{ alpha alpha stop alpha }.join("\n"), @tracer.to_s
  end

end

