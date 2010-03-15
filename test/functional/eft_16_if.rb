
#
# testing ruote
#
# Thu Jul  9 12:40:10 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


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

    assert_trace('then', pdef)
  end

  def test_else

    pdef = Ruote.process_definition :name => 'test' do
      _if :test => 'false' do
        echo 'then'
        echo 'else'
      end
    end

    #noisy

    assert_trace('else', pdef)
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

    assert_trace('done.', pdef)
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

    assert_trace('done.', pdef)
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

    assert_trace('then', pdef)
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

    assert_trace('else', pdef)
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

    assert_trace('done.', pdef)
  end

  def test_attribute_text

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        _if 'true' do
          echo 'then'
          echo 'else'
        end
        _if 'false' do
          echo 'then'
          echo 'else'
        end
        _if false do
          echo 'then'
          echo 'else'
        end
        _if :test => false do
          echo 'then'
          echo 'else'
        end
      end
    end

    #noisy

    assert_trace(%w[ then else else else ], pdef)
  end

  def test_xml_equals

    require_json
    Rufus::Json.detect_backend
      # making sure JSON dup is available in case of HashStorage

    pdef = %{
      <?xml version="1.0"?>
      <process-definition name="test_xml">
        <if>
          <equals field-value="state" other-value="A" />
          <echo>alpha</echo>
          <echo>bravo</echo>
        </if>
      </process-definition>
    }

    assert_trace('alpha', { 'state' => 'A' }, pdef)

    @tracer.clear

    assert_trace('alpha', { :state => 'A' }, pdef)
  end
end

