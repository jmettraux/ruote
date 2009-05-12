
#
# Testing Ruote (OpenWFEru)
#
# Sat Jan 24 22:40:35 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftProcessDefinitionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_procdef

    assert_trace(
      Ruote.define(:name => 'test_1') { },
      '')
  end
end

