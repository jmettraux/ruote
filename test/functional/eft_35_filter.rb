
#
# testing ruote
#
# Mon Jan 31 14:45:09 JST 2011
#

require File.expand_path('../base', __FILE__)


class EftFilterTest < Test::Unit::TestCase
  include FunctionalBase

  def assert_terminates(pdef, fields, result=nil)

    wfid = @dashboard.launch(pdef, fields)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']

    fields = r['workitem']['fields']
    fields.delete('__result__')

    assert_equal(result, fields) if result
  end

  def assert_does_not_validate(pdef, fields={})

    wfid = @dashboard.launch(pdef, fields)
    r = @dashboard.wait_for(wfid)

    err = @dashboard.errors.first

    assert_equal 'error_intercepted', r['action']
    assert_match /ValidationError/, err.message
    assert_equal Array, err.deviations.class

    #p @dashboard.ps(wfid)
  end

  #
  # the tests

  def test_filter_single_rule_validation

    pdef = Ruote.process_definition do
      filter 'x', :type => 'string'
    end

    assert_terminates(pdef, 'x' => 'nada')
  end

  def test_filter_single_rule__drop_if

    pdef = Ruote.process_definition do
      filter 'x', :type => 'string', :if => true
    end

    assert_terminates(pdef, 'x' => 'nada')
  end

  def test_filter_single_rule_validation_failure

    pdef = Ruote.process_definition do
      filter 'x', :type => 'string'
    end

    assert_does_not_validate(pdef, 'x' => 2)
  end

  def test_filter_single_rule_transformation

    pdef = Ruote.process_definition do
      filter 'x', :or => 'crimea'
    end

    assert_terminates(pdef, {}, { 'x' => 'crimea' })
  end

  def test_filter_single_rule_in

    pdef = Ruote.process_definition do
      filter 'colour', :in => %w[ red green blue ]
    end

    assert_terminates(pdef, 'colour' => 'green')
  end

  PDEF1 = Ruote.process_definition do
    filter :in => [
      { :field => 'x', :type => 'string' },
      { :field => 'y', :type => 'number' }
    ]
  end

  def test_filter_multiple_rules_validation

    assert_terminates(PDEF1, 'x' => 's', 'y' => 2)
  end

  def test_filter_multiple_rules_validation_failure

    assert_does_not_validate(PDEF1, 'x' => 's', 'y' => 's')
  end

  def test_filter_multiple_rules_transformation

    pdef = Ruote.process_definition do
      filter :in => [
        { :field => 'x', :or => 'alpha' },
        { :field => 'y', :or => 'bravo' }
      ]
    end

    assert_terminates(pdef, {}, { 'x' => 'alpha', 'y' => 'bravo' })
  end

  def test_filter_in_variable

    pdef = Ruote.process_definition do
      set 'v:toto' => [
        { :field => 'a', :set => 'A' },
        { :field => 'b', :or => 'B' },
      ]
      filter 'v:toto'
    end

    assert_terminates(pdef, {}, { 'a' => 'A', 'b' => 'B' })
  end

  def test_in_filter_in_variable

    # compatibility with the :filter attribute

    pdef = Ruote.process_definition do
      set 'v:toto' => { :in => [
        { :field => 'a', :set => 'A' },
        { :field => 'b', :or => 'B' },
      ] }
      filter 'v:toto'
    end

    assert_terminates(pdef, {}, { 'a' => 'A', 'b' => 'B' })
  end

  def test_filter_in_field

    pdef = Ruote.process_definition do
      set 'f:toto' => [
        { :field => 'a', :set => 'A' },
        { :field => 'b', :or => 'B' },
      ]
      filter 'f:toto'
      unset 'f:toto'
    end

    assert_terminates(pdef, {}, { 'a' => 'A', 'b' => 'B' })
  end

  def test_in_filter_in_field

    pdef = Ruote.process_definition do
      set 'f:toto' => { :in => [
        { :field => 'a', :set => 'A' },
        { :field => 'b', :or => 'B' },
      ] }
      filter 'f:toto'
      unset 'f:toto'
    end

    assert_terminates(pdef, {}, { 'a' => 'A', 'b' => 'B' })
  end

  def test_tilde

    # the ~ points to the hash as it was right before the filtering began

    pdef = Ruote.process_definition do
      filter :in => [
        { :field => 'x', :set => 'X' },
        { :field => 'x', :copy_from => '~.x' },
      ]
    end

    assert_terminates(pdef, { 'x' => 1 }, { 'x' => 1 })
  end

  def test_double_tilde

    # the ~~ points to the workitem fields as they are in the parent expression

    pdef = Ruote.process_definition do
      filter 'x', :set => 'X'
      filter 'x', :copy_from => '~~.x'
    end

    assert_terminates(pdef, { 'x' => 1 }, { 'x' => 1 })
  end

  def test_record

    pdef = Ruote.process_definition do
      filter 'x', :type => 'string', :record => true
    end

    assert_terminates(
      pdef,
      { 'x' => 1 },
      { '__validation_errors__' => [
          [ { 'type' => 'string', 'field' => 'x' }, 'x', 1 ]
        ],
        'x' => 1
      })
  end

  def test_record__complex

    pdef = Ruote.process_definition do
      filter :in => [
        { :field => 'x', :type => 'string', :record => true },
        { :field => 'y', :type => 'number' }
      ]
    end

    assert_terminates(
      pdef,
      { 'x' => 1 },
      { '__validation_errors__' => [
          [ { 'type' => 'string', 'field' => 'x' }, 'x', 1 ],
          [ { 'type' => 'number', 'field' => 'y' }, 'y', nil ]
        ],
        'x' => 1
      })
  end

  def test_record_in_designated_field

    pdef = Ruote.process_definition do
      filter 'x', :type => 'string', :record => 'verrors'
    end

    assert_terminates(
      pdef,
      { 'x' => 1 },
      { 'verrors' => [
          [ { 'type' => 'string', 'field' => 'x' }, 'x', 1 ]
        ],
        'x' => 1
      })
  end

  def test_record_accumulates

    pdef = Ruote.process_definition do
      filter 'x', :type => 'string', :record => true
      filter 'y', :type => 'number', :record => true
    end

    assert_terminates(
      pdef,
      { 'x' => 1 },
      { '__validation_errors__' => [
          [ { 'type' => 'string', 'field' => 'x' }, 'x', 1 ],
          [ { 'type' => 'number', 'field' => 'y' }, 'y', nil ]
        ],
        'x' => 1
      })
  end

  def test_record_flushes_and_accumulates

    pdef = Ruote.process_definition do
      filter 'x', :type => 'string', :record => true
      filter 'y', :type => 'number', :record => true, :flush => true
    end

    assert_terminates(
      pdef,
      { 'x' => 1 },
      { '__validation_errors__' => [
          [ { 'type' => 'number', 'field' => 'y' }, 'y', nil ]
        ],
        'x' => 1
      })
  end

  def test_filter_and_block

    pdef = Ruote.process_definition do
      filter do
        field 'x', :type => 'string'
        field 'y', :type => 'number'
      end
    end

    #@dashboard.noisy = true

    assert_terminates(pdef, 'x' => 's', 'y' => 2)
    assert_does_not_validate(pdef, 'x' => 's', 'y' => 's')
  end

  def test_filter_and_block__radial

    pdef = %{
      define
        filter
          f x, type: 'string'
          f y, type: 'number'
    }

    #@dashboard.noisy = true

    assert_terminates(pdef, 'x' => 's', 'y' => 2)
    assert_does_not_validate(pdef, 'x' => 's', 'y' => 's')
  end

  def test_filter_and_block__field_name_is_expname

    pdef = %{
      define
        filter
          x type: 'string'
          y type: 'number'
    }

    #@dashboard.noisy = true

    assert_terminates(pdef, 'x' => 's', 'y' => 2)
    assert_does_not_validate(pdef, 'x' => 's', 'y' => 's')
  end

  def test_filter_and_block__collision_with_if

    pdef = %{
      define
        filter if: true
          x type: 'string'
          y type: 'number'
    }

    #@dashboard.noisy = true

    assert_terminates(pdef, 'x' => 's', 'y' => 2)
    assert_does_not_validate(pdef, 'x' => 's', 'y' => 's')
  end

  def test_filter_block_and_or

    pdef = Ruote.process_definition do
      filter do
        field 'x', :type => 'string'
        _or
        field 'x', :type => 'number'
      end
    end

    #@dashboard.noisy = true

    assert_terminates(pdef, 'x' => 's')
    assert_terminates(pdef, 'x' => 5)
    assert_does_not_validate(pdef, 'x' => true)
  end

  def test_filter_block_and_or__radial

    pdef = %{
      define
        filter
          x type: 'string'
          or
          x type: 'number'
    }

    #@dashboard.noisy = true

    assert_terminates(pdef, 'x' => 's')
    assert_terminates(pdef, 'x' => 5)
    assert_does_not_validate(pdef, 'x' => true)
  end

  def test_cancel_filter_in_error

    #@dashboard.noisy = true

    pdef = Ruote.define do
      filter :in => [ { :field => 'x', :type => :number } ]
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal 1, @dashboard.ps(wfid).errors.size

    @dashboard.cancel(wfid)

    @dashboard.wait_for('terminated')

    assert_nil @dashboard.ps(wfid)
  end

  def test_cancel_filter_out_error

    #@dashboard.noisy = true

    pdef = Ruote.define do
      filter :out => [ { :field => 'x', :type => :number } ]
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal 1, @dashboard.ps(wfid).errors.size

    @dashboard.cancel(wfid)

    @dashboard.wait_for('terminated')

    assert_nil @dashboard.ps(wfid)
  end
end

