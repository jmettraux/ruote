
#
# testing ruote
#
# Mon Jan 31 14:45:09 JST 2011
#

require File.join(File.dirname(__FILE__), 'base')


class EftFilterTest < Test::Unit::TestCase
  include FunctionalBase

  PDEF0 = Ruote.process_definition do
    filter 'x', :type => 'string'
  end

  def test_filter_single_rule_validation

    wfid = @engine.launch(PDEF0, 'x' => 'nada')

    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end

  def test_filter_single_rule_validation_failure

    wfid = @engine.launch(PDEF0, 'x' => 2)

    r = @engine.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
    assert_match /ValidationError/, @engine.errors.first.message
  end

  def test_filter_single_rule_transformation

    pdef = Ruote.process_definition do
      filter 'x', :or => 'crimea'
    end

    #noisy

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 'crimea', r['workitem']['fields']['x']
  end

  def test_filter_single_rule_in

    pdef = Ruote.process_definition do
      filter 'colour', :in => %w[ red green blue ]
    end

    #noisy

    wfid = @engine.launch(pdef, 'colour' => 'green')

    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end

  PDEF1 = Ruote.process_definition do
    filter :in => [
      { :field => 'x', :type => 'string' },
      { :field => 'y', :type => 'number' }
    ]
  end

  def test_filter_multiple_rules_validation

    wfid = @engine.launch(PDEF1, 'x' => 's', 'y' => 2)

    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end

  def test_filter_multiple_rules_validation_failure

    wfid = @engine.launch(PDEF1, 'x' => 's', 'y' => 's')

    r = @engine.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
    assert_match /ValidationError/, @engine.errors.first.message
  end

  def test_filter_multiple_rules_transformation

    pdef = Ruote.process_definition do
      filter :in => [
        { :field => 'x', :or => 'alpha' },
        { :field => 'y', :or => 'bravo' }
      ]
    end

    #noisy

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal({ 'x' => 'alpha', 'y' => 'bravo' }, r['workitem']['fields'])
  end
end

