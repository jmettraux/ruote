
#
# testing ruote
#
# Thu May 21 15:29:48 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote'


class TreeTest < Test::Unit::TestCase

  def test_compact_tree_participant

    assert_equal(
      [ 'alpha', {}, [] ],
      Ruote.compact_tree(
        [ 'participant', { 'ref' => 'alpha' }, [] ]))

    assert_equal(
      [ 'alpha', {}, [] ],
      Ruote.compact_tree(
        [ 'participant', { 'alpha' => nil }, [] ]))

    assert_equal(
      [ 'alpha', { 'timeout' => '2d' }, [] ],
      Ruote.compact_tree(
        [ 'participant', { 'alpha' => nil, 'timeout' => '2d' }, [] ]))
  end

  def test_compact_tree_subprocess

    assert_equal(
      [ 'do_this', {}, [] ],
      Ruote.compact_tree(
        [ 'subprocess', { 'ref' => 'do_this' }, [] ]))

    assert_equal(
      [ 'do_this', {}, [] ],
      Ruote.compact_tree(
        [ 'subprocess', { 'do_this' => nil }, [] ]))
  end

  def test_compact_tree

    assert_equal(
      ["define", {}, [
        ["concurrence", {}, [
          ["alpha", {"timeout"=>"1d"}, []],
          ["alpha", {}, []]]],
        ["bravo", {}, []]]],
      Ruote.compact_tree(
        Ruote.define do
          concurrence do
            participant :ref => 'alpha', :timeout => '1d'
            subprocess 'alpha'
          end
          bravo
        end))
  end
end

