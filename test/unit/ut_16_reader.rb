
#
# testing ruote
#
# Tue Oct 20 10:48:11 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require_json
require 'ruote/reader'


class PdefReaderTest < Test::Unit::TestCase

  DEF0 = %{
    Ruote.define :name => 'nada' do
      sequence do
        alpha
        bravo
      end
    end
  }

  TREE1 = Ruote::Reader.read(%{
    Ruote.define :name => 'nada' do
      alpha
      participant 'bravo', :timeout => '2d', :on_board => true
      participant 'charly', :on_board => false, :whatever => nil
      doug :a => 'false', :b => 'true', :c => 'nil', :d => 4.5
      dec 'v:x'
    end
  })

  def test_from_string

    tree = Ruote::Reader.read(DEF0)

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
      ]],
      tree)
  end

  def test_from_file

    fn = File.join(File.dirname(__FILE__), '_ut_16_def.rb')

    File.open(fn, 'w') { |f| f.write(DEF0) }

    tree = Ruote::Reader.read(fn)

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
      ]],
      tree)

    FileUtils.rm_f(fn) # sooner or later, it will get erased
  end

  def test_to_xml

    assert_equal(
      %{
<?xml version="1.0" encoding="UTF-8"?>
<define name="nada">
  <alpha/>
  <participant on-board="true" ref="bravo" timeout="2d"/>
  <participant on-board="false" ref="charly" whatever="nil"/>
  <doug a="false" b="true" c="nil" d="4.5"/>
  <dec ref="v:x"/>
</define>
      }.strip,
      Ruote::Reader.to_xml(TREE1, :indent => 2).strip)
  end

  def test_if_to_xml

    tree = Ruote.process_definition do
      _if 'nada' do
        participant 'nemo'
      end
    end

    assert_equal(
      %{
<?xml version="1.0" encoding="UTF-8"?>
<define>
  <if test="nada">
    <participant ref="nemo"/>
  </if>
</define>
      }.strip,
      Ruote::Reader.to_xml(tree, :indent => 2).strip)
  end

  def test_to_ruby

    assert_equal(
      %{
Ruote.process_definition :name => "nada" do
  alpha
  participant "bravo", :on_board => true, :timeout => "2d"
  participant "charly", :on_board => false, :whatever => nil
  doug :a => "false", :b => "true", :c => "nil", :d => 4.5
  dec "v:x"
end
      }.strip,
      Ruote::Reader.to_ruby(TREE1).strip)
  end

  def test_to_json

    require 'json'

    assert_equal TREE1.to_json, Ruote::Reader.to_json(TREE1)
  end

  def test_to_radial

    assert_equal(
      %{
define name: nada
  alpha
  participant bravo, on_board: true, timeout: 2d
  participant charly, on_board: false, whatever: nil
  doug a: "false", b: "true", c: "nil", d: 4.5
  dec "v:x"
      }.strip,
      Ruote::Reader.to_radial(TREE1).strip)
  end

  def test_to_radial_back_and_forth

    rad = Ruote::Reader.to_radial(TREE1)

    assert_equal TREE1, Ruote::Reader.read(rad)
  end

  def test_to_radial_2

    tree = Ruote.define do
      participant 'bob', 'message' => "hello my\ndear world"
      participant 'charly', 'message' => 'oh my'
    end

    rad = Ruote::Reader.to_radial(tree)

    assert_equal tree, Ruote::Reader.read(rad)
  end

  def test_to_expid_radial

    assert_equal(
      %{  0  define name: nada
0_0    alpha
0_1    participant bravo, on_board: true, timeout: 2d
0_2    participant charly, on_board: false, whatever: nil
0_3    doug a: "false", b: "true", c: "nil", d: 4.5
0_4    dec "v:x"},
      Ruote::Reader.to_expid_radial(TREE1))
  end

  DEF1 = %{
Ruote.process_definition do
  sequence do
    alpha
    set :field => 'f', :value => 'v'
    bravo
  end
end
  }

  def test_from_ruby_file

    fn = File.expand_path(File.join(File.dirname(__FILE__), '_ut_16_def1.rb'))

    File.open(fn, 'wb') { |f| f.write(DEF1) }

    assert_equal(
      ["define", {}, [["sequence", {}, [["alpha", {}, []], ["set", {"field"=>"f", "value"=>"v"}, []], ["bravo", {}, []]]]]],
      Ruote::Reader.read(fn))

    FileUtils.rm(fn)
  end

  # Make sure that ruby method names like 'freeze' or 'clone' can be used
  # in process definitions.
  #
  def test_ruby_blank_slate

    t = Ruote::Reader.read(%{
      Ruote.define do
        freeze
        clone
        untrust
      end
    })

    assert_equal(
      [ 'define', {}, [
        [ 'freeze', {}, [] ], [ 'clone', {}, [] ], [ 'untrust', {}, [] ]
      ] ],
      t)
  end

  def test_radial

    tree = Ruote::Reader.read(%{
      define name: 'nada'
        sequence
          alpha
          participant bravo, timeout: 2d, on-board: true
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

  def test_parse_error__ruby

    err = nil

    begin
      Ruote::Reader.read(%{
        Ruote.process_definition # missing "do"
          alpha
        end
      })
    rescue => err
    end

    assert_equal Ruote::Reader::Error, err.class
    assert_equal Racc::ParseError, err.cause.class
  end

  def test_parse_error__radial

    err = nil

    begin
      Ruote::Reader.read(%{
        process_definition [f:y]
          alpha
      })
    rescue => err
    end

    assert_equal Ruote::Reader::Error, err.class
    assert_equal Parslet::UnconsumedInput, err.cause.class
  end

  def test_ruby_attributes

    pdef = Ruote.define do
      sequence :on_error => [
        { /unknown participant/ => 'alpha' },
        { nil => 'bravo' }
      ] do
        nada
      end
    end

    assert_equal(
      [ 'define', {}, [
        [ 'sequence', { 'on_error' => [
          { '/unknown participant/' => 'alpha' }, { nil => 'bravo' }
          ] }, [
          [ 'nada', {}, [] ]
        ] ]
      ] ],
      pdef)
  end
end

