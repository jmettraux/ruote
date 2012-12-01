
#
# testing ruote
#
# Thu Jul  9 12:40:10 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftIfTest < Test::Unit::TestCase
  include FunctionalBase

  def test_then

    pdef = Ruote.process_definition :name => 'test' do
      _if :test => 'true' do
        echo 'then'
        echo 'else'
      end
    end

    assert_trace('then', pdef)
  end

  def test_else

    pdef = Ruote.process_definition :name => 'test' do
      _if :test => 'false' do
        echo 'then'
        echo 'else'
      end
    end

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

    assert_trace(%w[ then else else else ], pdef)
  end

  # For ruote-mon and its dot/dollar escaping scheme.
  #
  # (Fukuoka Ruby Kaigi 01 2012/12/01)
  #
  def test_attribute_text_and_dots

    @dashboard.context['ruby_eval_allowed'] = true

    pdef = Ruote.define do
      _if '${r:"".length == 0}' do
      #_if :test => '${r:"".length == 0}' do
        echo 'a'
        echo 'b'
      end
      _if '${r:"".length == 1}' do
      #_if :test => '${r:"".length == 1}' do
        echo 'a'
        echo 'b'
      end
    end

    assert_trace(%w[ a b ], pdef)
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

  def test_t

    pdef = Ruote.define do
      _if :t => 'true' do
        echo 'then'
      end
      echo 'done.'
    end

    assert_trace("then\ndone.", pdef)
  end
end

