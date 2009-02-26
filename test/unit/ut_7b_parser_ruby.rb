
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/def'
require 'openwfe/expool/def_parser'


class ParserRubyTestB < Test::Unit::TestCase

  def do_test (class_name, pdef)
    #
    # losing my time with an eval
    #
    result = eval %{
      class #{class_name} < OpenWFE::ProcessDefinition
        def make
          participant 'nada'
        end
      end
      #{class_name}.do_make
    }
    assert_equal result[1]['name'], pdef[0]
    assert_equal result[1]['revision'], pdef[1]
  end

  def test_process_name_extraction_in_ruby_procdefs

    do_test 'MyProcessDefinition_10', [ 'MyProcess', '10' ]
    do_test 'MyProcessDefinition10', [ 'MyProcess', '10' ]
    do_test 'MyProcessDefinition1_0', [ 'MyProcess', '1.0' ]
    do_test 'MyProcessThing_1_0', [ 'MyProcessThing', '1.0' ]
  end

  def do_test_2 (raw_name, expected)

    assert_equal(
      expected,
      OpenWFE::ProcessDefinition.extract_name_and_revision(raw_name))
  end

  def test_process_name_extraction_in_ruby_procdefs_2

    do_test_2 'MyProcessDefinition_10', [ 'MyProcess', '10' ]
    do_test_2 'MyProcessDefinition5b', [ 'MyProcess', '5b' ]
  end

end

