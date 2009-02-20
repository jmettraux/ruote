
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Feb  3 16:40:16 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftUnsetTest < Test::Unit::TestCase
  include FunctionalBase

  def test_unset_variables

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        set :v => 'v0', :val => 'a'
        set :v => 'v1', :val => 'b'
        set :v => 'v2', :val => 'c'

        echo '${v0}${v1}${v2}'

        unset :v => 'v0'
        unset :var => 'v1'
        unset :variable => 'v2'

        echo '..${v0}${v1}${v2}'
      end
    end

    assert_trace(pdef, "abc\n..")
  end

  def test_unset_fields

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do

        set :f => 'f0', :val => 'a'
        set :f => 'f1', :val => 'b'
        set :f => 'f2', :val => 'c'

        echo '${f:f0}${f:f1}${f:f2}'

        unset :f => 'f0'
        unset :fld => 'f1'
        unset :field => 'f2'

        echo '..${f:f0}${f:f1}${f:f2}'
      end
    end

    assert_trace(pdef, "abc\n..")
  end
end

