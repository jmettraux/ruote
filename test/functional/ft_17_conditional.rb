
#
# Testing Ruote (OpenWFEru)
#
# Fri Jul  3 19:46:22 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtConditionalTest < Test::Unit::TestCase
  include FunctionalBase

  def test_string_equality

    pdef = Ruote.process_definition :name => 'test' do

      set :f => 'd', :val => '2'

      sequence do

        echo '${f:d}'

        echo 'a', :if => '${f:d}'
        echo 'b', :if => '${f:d} == 2'
        echo 'c', :if => "${f:d} == '2'"
        echo 'd', :if => '${f:d} is set'
      end
    end

    assert_trace(pdef, %w[ 2 a b d ])
  end

  def test_string_equality_when_space

    pdef = Ruote.process_definition :name => 'test' do

      set :f => 'd', :val => 'some dude'

      sequence do

        echo '${f:d}'

        echo 'a', :if => '${f:d}'
        echo 'b', :if => '${f:d} == some dude'
        echo 'c', :if => "${f:d} == 'some dude'"
        echo 'd', :if => '${f:d} is set'
      end
    end

    assert_trace(pdef, "some dude\na\nb\nd")
  end
end

