
#
# testing ruote
#
# Sat Dec 25 12:21:00 JST 2010
#

require File.expand_path('../base', __FILE__)


class EftGivenTest < Test::Unit::TestCase
  include FunctionalBase

  def test_given_that

    pdef = Ruote.process_definition do
      given do
        that "${state} == ready" do
          echo "a"
        end
        that "${location} == nichoume" do
          echo "b"
        end
        # anything that follows is "else"
        echo "c"
        echo "d"
      end
    end

    #noisy

    assert_trace %w[ c d ], pdef, :clear
    assert_trace %w[ a ], { 'state' => 'ready' }, pdef, :clear
    assert_trace %w[ b ], { 'location' => 'nichoume' }, pdef, :clear
    assert_trace %w[ a ], { 'state' => 'ready', 'location' => 'nichoume' }, pdef, :clear
  end

  def test_given_x_of

    pdef = Ruote.process_definition do
      given "${status}" do
        of "ready" do
          echo "a"
        end
        of "dead" do
          echo "b"
        end
        echo "c"
        echo "d"
      end
    end

    #noisy

    assert_trace %w[ c d ], pdef, :clear
    assert_trace %w[ a ], { 'status' => 'ready' }, pdef, :clear
    assert_trace %w[ b ], { 'status' => 'dead' }, pdef, :clear
  end

  def test_given_x_of_and_that

    pdef = Ruote.process_definition do
      given "${status}" do
        that "${location} == higashiyama" do
          echo "a"
        end
        of "ready" do
          echo "b"
        end
        of "dead" do
          echo "c"
        end
        echo "d"
      end
    end

    assert_trace %w[ d ], {}, pdef, :clear
    assert_trace %w[ b ], { 'status' => 'ready' }, pdef, :clear
    assert_trace %w[ a ], { 'status' => 'dead', 'location' => 'higashiyama' }, pdef, :clear
  end

  def test_attributes

    pdef = Ruote.process_definition do
      given :t => "${status}" do
        that :t => "${location} == higashiyama" do
          echo "a"
        end
        of :t => "ready" do
          echo "b"
        end
        of "dead" do
          echo "c"
        end
        echo "d"
      end
    end

    assert_trace %w[ d ], {}, pdef, :clear
    assert_trace %w[ b ], { 'status' => 'ready' }, pdef, :clear
    assert_trace %w[ a ], { 'status' => 'dead', 'location' => 'higashiyama' }, pdef, :clear
  end

  def test_match

    pdef = Ruote.define do
      given "${status}" do
        of "/^a/" do
          echo 'a'
        end
        of /^b/ do
          echo 'b'
        end
        echo 'z'
      end
    end

    assert_trace %w[ z ], {}, pdef, :clear
    assert_trace %w[ a ], { 'status' => 'alpha' }, pdef, :clear
    assert_trace %w[ b ], { 'status' => 'bravo' }, pdef, :clear
  end
end

