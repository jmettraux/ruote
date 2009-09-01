
#
# Testing Ruote (OpenWFEru)
#
# Tue Jun 23 11:16:39 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtVariablesTest < Test::Unit::TestCase
  include FunctionalBase

  def test_wfid_and_expid

    pdef = Ruote.process_definition do
      echo 'at:${wfid}:${expid}'
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    assert_equal "at:#{wfid}:0_0", @tracer.to_s
  end

  def test_variables_event

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'v', :val => 'x'
        unset :var => 'v'
        echo 'done.'
      end
    end

    #noisy

    assert_trace(pdef, 'done.')

    assert_equal(
      1, logger.log.select { |e| e[0] == :variables && e[1] == :set }.size)
    assert_equal(
      1, logger.log.select { |e| e[0] == :variables && e[1] == :unset }.size)
  end

  def test_process_root_variables

    pdef = Ruote.process_definition do
      sequence do
        set 'v:va' => 'a0'
        set 'v:/vb' => 'b0'
        echo '${v:va}:${v:vb}:${v:/va}:${v:/vb}'
        sub0
        echo '${v:va}:${v:vb}:${v:/va}:${v:/vb}'
      end
      define 'sub0' do
        set 'v:va' => 'a1'
        set 'v:/vb' => 'b1'
        echo '${v:va}:${v:vb}:${v:/va}:${v:/vb}'
      end
    end

    #noisy

    assert_trace(pdef, %w[ a0:b0:a0:b0 a1:b1:a0:b1 a0:b1:a0:b1 ])
  end
end

