
#
# testing ruote
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
        echo 'e', :if => '${f:e} is set'
      end
    end

    assert_trace(%w[ 2 a b d ], pdef)
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

    assert_trace("some dude\na\nb\nd", pdef)
  end

  def test_unless

    pdef = Ruote.process_definition :name => 'test' do

      echo '${f:f}'
      echo 'u', :unless => '${f:f} == 2000'
      echo 'i', :if => '${f:f} == 2000'
      echo '.'
    end

    assert_trace(%w[ 2000 i . ], { 'f' => 2000 }, pdef)

    @tracer.clear

    assert_trace(%w[ 2000 i . ], { 'f' => '2000' }, pdef)

    @tracer.clear

    assert_trace(%w[ other u . ], { 'f' => 'other' }, pdef)
  end
end

