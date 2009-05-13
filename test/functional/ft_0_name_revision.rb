
#
# Testing Ruote (OpenWFEru)
#
# Wed May 13 11:14:08 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtNameRevisionTest < Test::Unit::TestCase
  include FunctionalBase

  def teardown

    @engine.stop
    purge_engine
  end

  def test_no_name

    pdef = Ruote.process_definition do
    end

    fei = assert_trace pdef, ''

    ps = @engine.process_status(fei.wfid)

    assert_equal 'no-name', ps.definition_name
    assert_equal '0', ps.definition_revision
  end
end

