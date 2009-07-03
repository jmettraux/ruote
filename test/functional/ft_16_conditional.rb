
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Jul  3 19:30:27 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtConditionalTest < Test::Unit::TestCase
  include FunctionalBase

  def test_string_equality

    pdef = OpenWFE.process_definition :name => 'test' do

      set_fields :value => { 'd' => 2 }

      sequence do

        echo '${f:d}'

        _if :test => '${f:d}' do
          echo 'atrue' # <--
          echo 'afalse'
        end
        _if :test => '${f:d} == 2' do
          echo 'btrue' # <--
          echo 'bfalse'
        end
        _if :test => "${f:d} == '2'" do
          echo 'ctrue'
          echo 'cfalse'
        end
        _if :test => '${f:d} is set' do
          echo 'dtrue' # <--
          echo 'dfalse'
        end
      end
    end

    assert_trace(pdef, %w[ 2 atrue btrue cfalse dtrue ].join("\n"))
  end

  def test_string_equality_when_space

    pdef = OpenWFE.process_definition :name => 'test' do

      set_fields :value => { 'd' => 'some dude' }

      sequence do

        echo '${f:d}'

        _if :test => '${f:d}' do
          echo 'atrue' # <--
          echo 'afalse'
        end
        _if :test => '${f:d} == some dude' do
          echo 'btrue' # <--
          echo 'bfalse'
        end
        _if :test => "${f:d} == 'some dude'" do
          echo 'ctrue'
          echo 'cfalse'
        end
        _if :test => '${f:d} is set' do
          echo 'dtrue' # <--
          echo 'dfalse'
        end
      end
    end

    assert_trace(pdef, "some dude\natrue\nbtrue\ncfalse\ndtrue")
  end
end

