
#
# testing ruote
#
# Fri Dec 24 14:53:30 JST 2010
#

require File.expand_path('../base', __FILE__)


#
# Tests about replacement for case x when 'y' and switch(x) constructs.
#
class FtCaseTest < Test::Unit::TestCase
  include FunctionalBase

  # The alternatives are bound at the process level
  #
  def test_open_lambda

    pdef = Ruote.define do

      define 'a' do
        set 'f:result' => 'a'
      end
      define 'b' do
        set 'f:result' => 'b'
      end

      subprocess '${the_case}'
    end

    wfid = @dashboard.launch(pdef, 'the_case' => 'a')
    r = @dashboard.wait_for(wfid)
    assert_equal 'a', r['workitem']['fields']['result']

    wfid = @dashboard.launch(pdef, 'the_case' => 'b')
    r = @dashboard.wait_for(wfid)
    assert_equal 'b', r['workitem']['fields']['result']
  end

  # The alternatives are bound inside of the case subprocess (definition)
  #
  def test_nested_lambda

    pdef = Ruote.define do

      define 'case' do
        define 'a' do
          set 'f:result' => 'a'
        end
        define 'b' do
          set 'f:result' => 'b'
        end
        subprocess '${the_case}'
      end

      subprocess 'case'
    end

    wfid = @dashboard.launch(pdef, 'the_case' => 'a')
    r = @dashboard.wait_for(wfid)
    assert_equal 'a', r['workitem']['fields']['result']

    wfid = @dashboard.launch(pdef, 'the_case' => 'b')
    r = @dashboard.wait_for(wfid)
    assert_equal 'b', r['workitem']['fields']['result']
  end

  # /!\
  #
  # Works as well, but the cases are bound in the global/process scope
  #
  def test_local_lambda

    pdef = Ruote.define do

      sequence do
        define 'a' do
          set 'f:result' => 'a'
        end
        define 'b' do
          set 'f:result' => 'b'
        end
        subprocess '${the_case}'
      end

      subprocess 'a' # /!\
    end

    wfid = @dashboard.launch(pdef, 'the_case' => 'a')
    r = @dashboard.wait_for(wfid)
    assert_equal 'a', r['workitem']['fields']['result']

    wfid = @dashboard.launch(pdef, 'the_case' => 'b')
    r = @dashboard.wait_for(wfid)
    assert_equal 'a', r['workitem']['fields']['result']
  end

  # Works as well, but the cases are bound in the global/process scope
  #
  def test_let_lambda

    pdef = Ruote.define do

      define 'a' do
        echo 'global_a'
      end

      let do
        define 'a' do
          echo 'a'
        end
        define 'b' do
          echo 'b'
        end
        subprocess '${the_case}'
      end

      subprocess 'a'
    end

    wfid = @dashboard.launch(pdef, 'the_case' => 'a')
    @dashboard.wait_for(wfid)
    assert_equal %w[ a global_a ], @tracer.to_a

    @tracer.clear

    wfid = @dashboard.launch(pdef, 'the_case' => 'b')
    @dashboard.wait_for(wfid)
    assert_equal %w[ b global_a ], @tracer.to_a
  end
end

