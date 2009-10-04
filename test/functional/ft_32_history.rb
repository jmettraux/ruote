
#
# Testing Ruote (OpenWFEru)
#
# Sun Oct  4 00:14:27 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/log/fs_history'


class FtHistoryTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch

    pdef = Ruote.process_definition do
      alpha
      echo 'done.'
    end

    #noisy

    history = @engine.add_service(:s_history, Ruote::FsHistory)

    @engine.register_participant :alpha do |workitem|
      # do nothing
    end

    wfid0 = assert_trace(pdef, "done.")
    wfid1 = assert_trace(pdef, "done.\ndone.")

    lines = File.readlines(Dir['work/log/*'].first)

    assert_equal 8, lines.size
    lines.each { |l| puts l }

    h = history.process_history(wfid0)
    assert_equal 4, h.size
    assert_equal Time, h.first.first.class
  end

  def test_subprocess

    flunk
  end
end

