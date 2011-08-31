
#
# testing ruote
#
# Sat Sep 20 23:40:10 JST 2008
#

#class String
#  def empty?
#    puts '=' * 80
#    puts caller.join("\n")
#    return (size == 0)
#  end
#end

#require 'perftools'
#PerfTools::CpuProfiler.start("/tmp/out.profile")

#def require (o)
#  p o
#  Kernel.require(o)
#end

#require 'profile'

require File.expand_path('../base', __FILE__)


class EftEchoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_echo

    pdef = Ruote.process_definition :name => 'test' do
      echo 'a'
    end

    #noisy

    assert_trace('a', pdef)
  end

  def test_echo_text

    pdef = Ruote.define do
      echo :text => 'a'
    end

    assert_trace('a', pdef)
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

