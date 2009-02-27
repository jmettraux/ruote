
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Feb 27 22:12:39 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtParametersTest < Test::Unit::TestCase
  include FunctionalBase

  PDEF0 = OpenWFE.process_definition :name => 'test' do
    parameter :field => 'address'
    sequence do
      echo '${f:address}'
    end
  end

  def test_missing_field

    #e = assert_raise(OpenWFE::ParameterException) {
    e = assert_raise(ArgumentError) {
      @engine.launch(PDEF0)
    }
    assert_equal "field 'address' is missing", e.message
  end

  def test_field_not_missing

    li = OpenWFE::LaunchItem.new(PDEF0)
    li.address = 'nihonbashi'

    assert_trace li, 'nihonbashi'
  end

  def test_field_default_value

    pdef = OpenWFE.process_definition :name => 'test' do
      parameter :field => 'address', :default => 'unknown'
      echo '${f:address}'
    end

    assert_trace pdef, 'unknown'
  end

  def test_field_type_boxing

    pdef = OpenWFE.process_definition :name => 'test' do
      parameter :field => 'address', :type => :string
      parameter :field => 'number', :type => :int
      echo '${f:address}/${ru:wi.number * 2}'
    end

    li = OpenWFE::LaunchItem.new(pdef)
    li.address = 3
    li.number = '4'

    assert_trace li, '3/8'
  end

  def test_field_type_boxing_fail

    pdef = OpenWFE.process_definition :name => 'test' do
      parameter :field => 'number', :type => :int
    end

    e = assert_raise(ArgumentError) {
      li = OpenWFE::LaunchItem.new(pdef)
      li.number = 'douze'
      @engine.launch(li)
    }
    assert_equal 'invalid value for Integer: "douze"', e.message
  end

  def test_field_default_value_and_boxing

    pdef = OpenWFE.process_definition :name => 'test' do
      parameter :field => 'number', :default => '3', :type => :int
      echo '${r:wi.number * 3}'
    end

    assert_trace pdef, '9'
  end

  def test_field_match_fail

    pdef = OpenWFE.process_definition :name => 'test' do
      parameter :field => 'phone', :match => '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'
    end

    e = assert_raise(ArgumentError) {
      li = OpenWFE::LaunchItem.new(pdef)
      li.phone = 'aa'
      @engine.launch(li)
    }
    assert_equal "value of field 'phone' doesn't match", e.message
  end
end

