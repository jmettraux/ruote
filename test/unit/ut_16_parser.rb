
#
# testing ruote
#
# Tue Oct 20 10:48:11 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/parser'


class PdefParserTest < Test::Unit::TestCase

  DEF0 = %{
    Ruote.define :name => 'nada' do
      sequence do
        alpha
        bravo
      end
    end
  }


  TREE1 = Ruote::Parser.parse(%{
    Ruote.define :name => 'nada' do
      sequence do
        alpha
        participant 'bravo', :timeout => '2d', :on_board => true
      end
    end
  })

  def test_from_string

    tree = Ruote::Parser.parse(DEF0)

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
      ]],
      tree)
  end

  def test_from_file

    fn = File.join(File.dirname(__FILE__), '_ut_16_def.rb')

    File.open(fn, 'w') { |f| f.write(DEF0) }

    tree = Ruote::Parser.parse(fn)

    assert_equal(
      ["define", {"name"=>"nada"}, [
        ["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]
      ]],
      tree)

    FileUtils.rm_f(fn) # sooner or later, it will get erased
  end

  def test_to_xml

    #puts Ruote::Parser.to_xml(TREE1, :indent => 2)
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
      Ruote::Parser.to_xml(TREE1, :indent => 2).strip)
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
      Ruote::Parser.to_xml(tree, :indent => 2).strip)
  end

  def test_to_ruby

    #puts Ruote::Parser.to_ruby(TREE1)
    assert_equal(
      %{
Ruote.process_definition :name => "nada" do
  sequence do
    alpha
    participant "bravo", :timeout => "2d", :on_board => true
  end
end
      }.strip,
      Ruote::Parser.to_ruby(TREE1).strip)
  end

  def test_to_json

    require 'json'

    assert_equal TREE1.to_json, Ruote::Parser.to_json(TREE1)
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
      Ruote::Parser.parse(fn))

    FileUtils.rm(fn)
  end
end

