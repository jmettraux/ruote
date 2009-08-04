
#
# Testing Ruote (OpenWFEru)
#
# Wed May 20 09:23:01 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftSetTest < Test::Unit::TestCase
  include FunctionalBase

  def test_set_var

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'x', :value => '0'
        echo '-${v:x}-'
      end
    end

    #noisy

    assert_trace pdef, '-0-'
  end

  def test_set_var_in_subprocess

    pdef = Ruote.process_definition do
      sequence do
        echo 'a${v:x}'
        set :var => 'x', :value => '0'
        echo 'b${v:x}'
        sub0
        echo 'e${v:x}'
      end
      define 'sub0' do
        sequence do
          echo 'c${v:x}'
          set :var => 'x', :value => '1'
          echo 'd${v:x}'
        end
      end
    end

    #noisy

    assert_trace pdef, %w[ a b0 c0 d1 e0 ]
  end

  def test_unset_var

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'x', :value => '0'
        echo '-${v:x}-'
        unset :var => 'x'
        echo '-${v:x}-'
      end
    end

    #noisy

    assert_trace pdef, %w[ -0- -- ]
  end

  def test_set_field

    pdef = Ruote.process_definition do
      sequence do
        set :field => 'f', :value => '0'
        echo '-${f:f}-'
      end
    end

    #noisy

    assert_trace pdef, '-0-'
  end

  def test_set_field_to_array

    pdef = Ruote.process_definition do
      sequence do
        set :field => 'f', :value => %w[ a b c ]
        echo '-${f:f.1}-'
      end
    end

    #noisy

    assert_trace pdef, '-b-'
  end

  def test_set_field_deep

    pdef = Ruote.process_definition do
      sequence do
        set :field => 'f', :value => %w[ a b c ]
        set :field => 'f.1', :val => 'B'
        echo '-${f:f.0}${f:f.1}${f:f.2}-'
      end
    end

    #noisy

    assert_trace pdef, '-aBc-'
  end

  def test_missing_value

    pdef = Ruote.process_definition do
      set :field => 'f'
    end

    #noisy

    wfid = @engine.launch(pdef)

    sleep 0.450

    assert_equal 1, @engine.process(wfid).errors.size
  end
end

