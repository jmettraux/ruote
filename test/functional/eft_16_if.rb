
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Jul  9 12:40:10 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftIfTest < Test::Unit::TestCase
  include FunctionalBase

  def test_then

    pdef = Ruote.process_definition :name => 'test' do
      _if :test => 'true' do
        echo 'then'
        echo 'else'
      end
    end

    #noisy

    assert_trace(pdef, 'then')
  end

  def test_else

    pdef = Ruote.process_definition :name => 'test' do
      _if :test => 'false' do
        echo 'then'
        echo 'else'
      end
    end

    #noisy

    assert_trace(pdef, 'else')
  end

  def test_missing_then

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        _if :test => 'true' do
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace(pdef, 'done.')
  end

  def test_missing_else

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        _if :test => 'false' do
          echo 'then'
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace(pdef, 'done.')
  end

  def test_equals_true

    pdef = Ruote.process_definition :name => 'test' do
      _if do
        equals :val => 'a', :other_value => 'a'
        echo 'then'
        echo 'else'
      end
    end

    #noisy

    assert_trace(pdef, 'then')
  end

  def test_equals_false

    pdef = Ruote.process_definition :name => 'test' do
      _if do
        equals :val => 'a', :other_value => 'z'
        echo 'then'
        echo 'else'
      end
    end

    #noisy

    assert_trace(pdef, 'else')
  end

  def test_equals_true_no_then

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        _if do
          equals :val => 'a', :other_value => 'z'
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace(pdef, 'done.')
  end
end

