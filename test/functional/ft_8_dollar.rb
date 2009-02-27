
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Feb 27 23:18:40 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtDollarTest < Test::Unit::TestCase
  include FunctionalBase

  def test_field_default_value

    pdef = OpenWFE.process_definition :name => 'test' do

      set_fields :value => { 'a' => 'f:a', 'b' => 'f:b', 'd' => 2 }

      sequence do

        set :var => 'a', :val => 'v:a'
        set :var => 'c', :val => 'v:c'

        echo '${f:a}'
        echo '${v:a}'

        echo '${field:a}'
        echo '${variable:a}'

        echo '${vf:a}'
        echo '${fv:a}'

        echo '${vf:b}'
        echo '${fv:b}'
        echo '${vf:c}'
        echo '${fv:c}'

        echo '${r:1+2}'
        echo '${ru:4+3}'

        echo '${r:wi.d * 2}'
        echo '${r:workitem.d * 3}'
      end
    end

    assert_trace(
      pdef, %w{ f:a v:a f:a v:a v:a f:a f:b f:b v:c v:c 3 7 4 6 }.join("\n"))
  end
end

