
#
# testing ruote
#
# Fri Dec 24 14:53:30 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')


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

    wfid = @engine.launch(pdef, 'the_case' => 'a')
    r = @engine.wait_for(wfid)
    assert_equal 'a', r['workitem']['fields']['result']

    wfid = @engine.launch(pdef, 'the_case' => 'b')
    r = @engine.wait_for(wfid)
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

    wfid = @engine.launch(pdef, 'the_case' => 'a')
    r = @engine.wait_for(wfid)
    assert_equal 'a', r['workitem']['fields']['result']

    wfid = @engine.launch(pdef, 'the_case' => 'b')
    r = @engine.wait_for(wfid)
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

    wfid = @engine.launch(pdef, 'the_case' => 'a')
    r = @engine.wait_for(wfid)
    assert_equal 'a', r['workitem']['fields']['result']

    wfid = @engine.launch(pdef, 'the_case' => 'b')
    r = @engine.wait_for(wfid)
    assert_equal 'a', r['workitem']['fields']['result']
  end
end

