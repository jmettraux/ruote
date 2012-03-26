
#
# testing ruote
#
# Tue Jan 17 11:22:25 JST 2012
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote'


class ProcessStatusTest < Test::Unit::TestCase

  # Should cover the orphan workitem case.
  #
  def test_empty_status

    ps = Ruote::ProcessStatus.new(nil, [], [], [], [], [])

    assert_equal nil, ps.root_expression
    assert_equal nil, ps.variables
    assert_equal nil, ps.all_variables
    assert_equal nil, ps.tags
    assert_equal nil, ps.current_tree
  end

  # kept in the fridge for now
  #
#  def test_from_h
#
#    h =
#      {"expressions"=>
#        [{"fei"=>
#           {"engine_id"=>"engine",
#            "wfid"=>"20120321-0931-dijiwari-napobemi",
#            "subid"=>"140b3e7a7339c0c42fc4b9520ad079d3",
#            "expid"=>"0"},
#          "variables"=>
#           {"my process"=>
#             ["0",
#              ["define",
#               {"name"=>"my process"},
#               [["participant", {"ref"=>"alpha"}, []]]]]},
#          "applied_workitem"=>
#           {"fields"=>{"workitem"=>{"kilroy"=>"was here"}},
#            "wf_name"=>"my process",
#            "wf_revision"=>nil,
#            "fei"=>
#             {"engine_id"=>"engine",
#              "wfid"=>"20120321-0931-dijiwari-napobemi",
#              "subid"=>"140b3e7a7339c0c42fc4b9520ad079d3",
#              "expid"=>"0"}},
#          "original_tree"=>
#           ["define",
#            {"name"=>"my process"},
#            [["participant", {"ref"=>"alpha"}, []]]],
#          "_id"=>
#           "0!140b3e7a7339c0c42fc4b9520ad079d3!20120321-0931-dijiwari-napobemi",
#          "type"=>"expressions",
#          "name"=>"sequence",
#          "children"=>
#           [{"engine_id"=>"engine",
#             "wfid"=>"20120321-0931-dijiwari-napobemi",
#             "subid"=>"b6a89a662f81f8b87e4e85d8e8368772",
#             "expid"=>"0_0"}],
#          "created_time"=>"2012-03-21 09:31:50.665988 UTC",
#          "on_cancel"=>nil,
#          "on_error"=>nil,
#          "on_timeout"=>nil,
#          "on_terminate"=>nil,
#          "put_at"=>"2012-03-21 09:31:50.670573 UTC",
#          "_rev"=>1,
#          "has_timers"=>false},
#         {"fei"=>
#           {"engine_id"=>"engine",
#            "wfid"=>"20120321-0931-dijiwari-napobemi",
#            "subid"=>"b6a89a662f81f8b87e4e85d8e8368772",
#            "expid"=>"0_0"},
#          "parent_id"=>
#           {"engine_id"=>"engine",
#            "wfid"=>"20120321-0931-dijiwari-napobemi",
#            "subid"=>"140b3e7a7339c0c42fc4b9520ad079d3",
#            "expid"=>"0"},
#          "applied_workitem"=>
#           {"fields"=>
#             {"workitem"=>{"kilroy"=>"was here"}, "params"=>{"ref"=>"alpha"}},
#            "wf_name"=>"my process",
#            "wf_revision"=>nil,
#            "fei"=>
#             {"engine_id"=>"engine",
#              "wfid"=>"20120321-0931-dijiwari-napobemi",
#              "subid"=>"b6a89a662f81f8b87e4e85d8e8368772",
#              "expid"=>"0_0"},
#            "participant_name"=>"alpha",
#            "re_dispatch_count"=>0},
#          "original_tree"=>["participant", {"ref"=>"alpha"}, []],
#          "_id"=>
#           "0_0!b6a89a662f81f8b87e4e85d8e8368772!20120321-0931-dijiwari-napobemi",
#          "type"=>"expressions",
#          "name"=>"participant",
#          "children"=>[],
#          "created_time"=>"2012-03-21 09:31:50.700773 UTC",
#          "on_cancel"=>nil,
#          "on_error"=>nil,
#          "on_timeout"=>nil,
#          "on_terminate"=>nil,
#          "put_at"=>"2012-03-21 09:31:50.713114 UTC",
#          "_rev"=>2,
#          "has_timers"=>false,
#          "participant_name"=>"alpha",
#          "participant"=>["Ruote::StorageParticipant", {}],
#          "dispatched"=>true}],
#       "errors"=>[],
#       "workitems"=>
#        [{"fields"=>
#           {"workitem"=>{"kilroy"=>"was here"},
#            "params"=>{"ref"=>"alpha"},
#            "dispatched_at"=>"2012-03-21 09:31:50.705732 UTC"},
#          "wf_name"=>"my process",
#          "wf_revision"=>nil,
#          "fei"=>
#           {"engine_id"=>"engine",
#            "wfid"=>"20120321-0931-dijiwari-napobemi",
#            "subid"=>"b6a89a662f81f8b87e4e85d8e8368772",
#            "expid"=>"0_0"},
#          "participant_name"=>"alpha",
#          "re_dispatch_count"=>0,
#          "type"=>"workitems",
#          "_id"=>
#           "wi!0_0!b6a89a662f81f8b87e4e85d8e8368772!20120321-0931-dijiwari-napobemi",
#          "wfid"=>"20120321-0931-dijiwari-napobemi",
#          "put_at"=>"2012-03-21 09:31:50.705819 UTC",
#          "_rev"=>0}],
#       "schedules"=>[],
#       "trackers"=>[]}
#
#    ps = Ruote::ProcessStatus.from_h(h)
#
#    pp ps
#  end
end

