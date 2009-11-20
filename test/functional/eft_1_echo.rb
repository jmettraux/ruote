
#
# Testing Ruote (OpenWFEru)
#
# Sat Sep 20 23:40:10 JST 2008
#

#require 'perftools'
#PerfTools::CpuProfiler.start("/tmp/out.profile")

#def require (o)
#  p o
#  Kernel.require(o)
#end

require File.join(File.dirname(__FILE__), 'base')


class EftEchoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_echo

    pdef = Ruote.process_definition :name => 'test' do
      echo 'a'
    end

    #noisy

    #100.times {
    #  @tracer.trace.clear
      assert_trace(pdef, 'a')
    #}
  end

  #def test_print_escape
  #  pdef = OpenWFE.process_definition :name => 'test' do
  #    sequence do
  #      set :v => 'toto', :value => 'otot'
  #      echo '${toto}', :escape => 'true'
  #      echo '${toto}', :escape => true
  #      echo :escape => true do
  #        '${toto}'
  #      end
  #    end
  #  end
  #  assert_trace(
  #    pdef,
  #    ([ '${toto}' ] * 3).join("\n"))
  #end
end

