
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Apr  4 11:17:56 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftIteratorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_iterator_on_string_value

    pdef = OpenWFE.process_definition :name => 'test' do
      iterator :on_value => 'x, y, z', :to_variable => 'v0' do
        echo '${f:__ip__} -- ${v0}'
      end
    end

    assert_trace(pdef, [ '0 -- x', '1 -- y', '2 -- z' ].join("\n"))
  end

  def test_iterator_on_array_value

    pdef = OpenWFE.process_definition :name => 'test' do
      iterator :on_value => %w{ x y z }, :to_variable => 'v0' do
        echo '${v0}'
      end
    end

    assert_trace(pdef, %w{ x y z }.join("\n"))
  end

  def test_iterator_to_field

    pdef = OpenWFE.process_definition :name => 'test' do
      iterator :on_value => %w{ x y z }, :to_field => 'f0' do
        echo '${f:f0}'
      end
    end

    assert_trace(pdef, %w{ x y z }.join("\n"))
  end

  def test_iterator_value_separator

    pdef = OpenWFE.process_definition :name => 'test' do
      iterator :on_value => 'xayaz', :to_variable => 'v0', :value_separator => 'a' do
        echo '${v0}'
      end
    end

    assert_trace(pdef, %w{ x y z }.join("\n"))
  end

  def test_empty_iterator

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        iterator :on_variable_value => 'missing', :to_variable => 'v0' do
          echo '${v0}'
        end
        echo 'done.'
      end
    end

    assert_trace(pdef, 'done.')
  end

  def test_iterator_break

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        iterator :on_value => 'x, y, z', :to_variable => 'v0' do
          sequence do
            echo '${v0}'
            _break :if => '${f:__ip__} == 1'
          end
        end
        echo 'done.'
      end
    end

    assert_trace(pdef, "x\ny\ndone.")
  end

  def test_iterator_skip

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        iterator :on_value => 'a, b, c, d, e, f, g', :to_field => 'f0' do
          sequence do
            echo '${f:__ip__} -- ${f:f0}'
            skip 2, :if => '${f:__ip__} == 1'
          end
        end
        echo 'done.'
      end
    end

    assert_trace(pdef, %{
0 -- a
1 -- b
4 -- e
5 -- f
6 -- g
done.
      }.strip)
  end
end

