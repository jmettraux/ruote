
#
# Testing Ruote (OpenWFEru)
#
# Wed May 13 11:14:08 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtNameRevisionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_no_name

    pdef = Ruote.process_definition do
    end

    flunk

    fei = @engine.launch(pdef)

    p fei

    purge_engine # bad somehow, next tests may fail
  end
end

