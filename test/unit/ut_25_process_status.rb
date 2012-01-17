
#
# testing ruote
#
# Tue Jan 17 11:22:25 JST 2012
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote/dashboard/process_status'


class ProcessStatusTest < Test::Unit::TestCase

  # Should cover the orphan workitem case.
  #
  def test_empty_status

    ps = Ruote::ProcessStatus.new(nil, [], [], [], [])

    assert_equal nil, ps.root_expression
    assert_equal nil, ps.variables
    assert_equal nil, ps.all_variables
    assert_equal nil, ps.tags
    assert_equal nil, ps.current_tree
  end
end

