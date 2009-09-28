
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

  def test_engine_variables

    pdef = Ruote.process_definition do
      sequence do
        set 'v:va' => 'a0'
        echo '${v:va}:${v://va}'
        echo '${v:vb}:${v://vb}'
        echo 'done.'
      end
    end

    #noisy

    @engine.variables['vb'] = 'b0'

    assert_trace(pdef, %w[ a0: b0:b0 done. ])

    assert_equal(
      2, logger.log.select { |e| e[0] == :variables && e[1] == :set }.size)
  end

  # A test about a protected method in FlowExpression, quite low level.
  #
  def test_lookup_var_site

    pdef = Ruote.process_definition do
      sequence do
        sub0
        echo 'done.'
      end
      define 'sub0' do
        alpha
      end
    end

    results = []

    @engine.register_participant :alpha do |workitem, fexp|

      class << fexp
        public :locate_var
      end

      results << fexp.locate_var('//a')
      results << fexp.locate_var('/a').first.fei.brief
      results << fexp.locate_var('a').first.fei.brief
    end

    #noisy

    assert_trace pdef, 'done.'

    assert_equal nil, results[0]
    assert_equal '/0', results[1]
    assert_match /^\d+00\/0\_0$/, results[2]
  end
end

