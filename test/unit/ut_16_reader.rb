
#
# testing ruote
#
# Tue Oct 20 10:48:11 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

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
      sequence do
        alpha
        participant 'bravo', :timeout => '2d', :on_board => true
      end
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
  <sequence>
    <alpha/>
    <participant timeout="2d" on-board="true" ref="bravo"/>
  </sequence>
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
  sequence do
    alpha
    participant "bravo", :timeout => "2d", :on_board => true
  end
end
      }.strip,
      Ruote::Reader.to_ruby(TREE1).strip)
  end

  def test_to_json

    require 'json'

    assert_equal TREE1.to_json, Ruote::Reader.to_json(TREE1)
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

