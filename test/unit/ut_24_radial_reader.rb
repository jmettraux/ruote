# encoding: UTF-8

#
# testing ruote
#
# Sat Apr 30 13:22:49 JST 2011
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require_json
require 'ruote/reader/radial'


class RadialReaderTest < Test::Unit::TestCase

  #
  # tests focusing on attribute parsing (line parsing)

  class ReadError < RuntimeError
    def initialize(s, e)
      @string = s
      @error = e
    end
    def to_s
      "error while parsing >#{@string}< : #{@error.to_s}"
    end
    def backtrace
      @error.backtrace
    end
  end

  def self.assert_read(target_tree, s)
    @@i ||= 0
    self.instance_eval do
      define_method("test_#{@@i}") do
        begin
          assert_equal(target_tree, Ruote::RadialReader.read(s))
        rescue => e
          raise ReadError.new(s, e)
        end
      end
    end
    @@i = @@i + 1
  end

  # the tests themselves

  assert_read(
    [ 'define', {}, [] ],
    'define')
  assert_read(
    [ 'define', {}, [] ],
    'define # whatever')
  assert_read(
    [ 'concurrent_iterator', {}, [] ],
    'concurrent-iterator')
  assert_read(
    [ 'define', { 'alpha' => nil }, [] ],
    'define "alpha"')
  assert_read(
    [ 'define', { 'bravo' => nil }, [] ],
    'define "bravo" # whatever')
  assert_read(
    [ 'define', { 'name' => 'charly' }, [] ],
    'define name: "charly"')
  assert_read(
    [ 'define', { 'name' => 'delta' }, [] ],
    'define name: "delta" # whatever')
  assert_read(
    [ 'define', { 'name' => 'echo' }, [] ],
    'define "name": "echo" # whatever')
  assert_read(
    [ 'define', { 'a' => 'AA', 'b' => 'BB' }, [] ],
    'define a: AA, b: BB # whatever')
  assert_read(
    [ 'define', { 'a' => 'A A', 'b' => 'B B' }, [] ],
    'define a: A A, b: B B')
  assert_read(
    [ 'define', { 'a' => 'A A', 'b' => 2.0 }, [] ],
    'define a: A A, b: 2.0')
  assert_read(
    [ 'define', { 'work_flow' => 'foxtrot' }, [] ],
    'define work-flow: foxtrot')
  assert_read(
    [ 'define', { 'work_flow' => 'gamma' }, [] ],
    'define "work-flow": gamma')
  assert_read(
    [ 'define', { 'work_flow' => 'hotel' }, [] ],
    'define "work-flow": "hotel"')
  assert_read(
    [ 'define', { 'india' => nil, 'mount' => 'batten' }, [] ],
    'define "india", mount: batten # whatever')
  assert_read(
    [ 'romeo', { 'timeout' => '2d'}, [] ],
    'romeo timeout: 2d # whatever')

  # JSON arrays and objects

  assert_read(
    [ 'echo', { 'lima' => nil, 'a' => [ 1, 2, 3 ] }, [] ],
    'echo "lima", a: [ 1, 2, 3 ] # whatever')
  assert_read(
    [ 'echo', { 'oscar' => nil, 'a' => nil }, [] ],
    'echo "oscar", a: null')

  # Ruby misc

  assert_read(
    [ 'define', { 'name' => 'juliet' }, [] ],
    "define name: 'juliet'")
  assert_read(
    [ 'define', { 'name' => 'kilo', 'a' => 'b' }, [] ],
    "define name: 'kilo', a: b")
  assert_read(
    [ 'echo', { 'name' => 'mike', 'a' => { 'b' => 'c', 'd' => 'e' } }, [] ],
    "echo name: 'mike', a: { :b => :c, 'd' => \"e\" }")
  assert_read(
    [ 'echo', { 'november' => nil, 'a' => [ 'b', 'c' ], 'd' => [ 1, 2, true ] }, [] ],
    "echo 'november', a: [ :b, :c ], d: [ 1, 2, true ]")
  assert_read(
    [ 'echo', { 'papa' => nil, 'a' => nil }, [] ],
    'echo "papa", a: nil # whatever')
  assert_read(
    [ 'echo', { 'quebec' => nil, 'b' => [ 'A', 'B' ] }, [] ],
    'echo "quebec", b: %w[ A B ] # whatever')

  #
  # more complete tests

  def test_error_on_empty_string

    assert_raise ArgumentError do
      Ruote::RadialReader.read(%{
      })
    end
  end

  def test_sequence

    tree = Ruote::RadialReader.read(%{
      process_definition "nada"
        sequence
          alpha
          bravo
    })

    assert_equal(
      [ 'process_definition', { 'nada' => nil }, [
        [ 'sequence', {}, [ [ 'alpha', {}, []], [ 'bravo', {}, [] ] ] ]
      ]],
      tree)
  end

  def test_echo

    tree = Ruote::RadialReader.read(%{
define name: "nada"
  echo "la vida loca"
    })

    assert_equal(
      [ 'define', { 'name' => 'nada' }, [
        [ 'echo', { 'la vida loca' => nil }, [] ] ] ],
      tree)
  end

  def test_concurrent_iterator

    tree = Ruote::RadialReader.read(%{
process_definition name: "nada"
  concurrent_iterator on_field: "toti", to_field: "toto"
    })

    assert_equal(
      [ 'process_definition', { 'name' => 'nada' }, [
        [ 'concurrent_iterator', { 'on_field' => 'toti', 'to_field' => 'toto' }, [] ] ] ],
      tree)
  end

  def test_multiline_strings

    tree = Ruote::RadialReader.read(%{
      process_definition "zama"
        echo """
          nada
        """, ol: korrect
        echo """
          #nada
        """
        # just a comment
        echo """
          'hola'
        """
    })

    assert_equal(
      [ 'process_definition', { 'zama' => nil }, [
        [ 'echo', { "\n          nada\n        " => nil, 'ol' => 'korrect' }, [] ],
        [ 'echo', { "\n          #nada\n        " => nil }, [] ],
        [ 'echo', { "\n          'hola'\n        " => nil }, [] ]
      ]],
      tree)
  end

  def test_unicode

    tree = Ruote::RadialReader.read(%{
      process_definition "nada"
        echo "très bon"
    })

    assert_equal(
      [ 'process_definition', { 'nada' => nil }, [
        [ 'echo', { 'très bon' => nil }, [] ]
      ]],
      tree)
  end

  def test_again

    tree = Ruote::RadialReader.read(%{
      define name: 'nada'
        sequence
          alpha
          participant bravo, timeout: '2d', on-board: true
    })

    assert_equal(
      [ 'define', { 'name' => 'nada' }, [
        [ 'sequence', {}, [
          [ 'alpha', {}, [] ],
          [ 'participant', { 'bravo' => nil, 'timeout' => '2d', 'on_board' => true }, [] ]
        ] ]
      ] ],
      tree)
  end
end

