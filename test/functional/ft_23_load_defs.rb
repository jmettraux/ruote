
#
# testing ruote
#
# Wed Aug  5 08:35:38 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtLoadDefsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_load_definition

    pdef = %{
Ruote.process_definition :name => 'test' do
  sequence do
    echo 'a'
    echo 'b'
  end
end
    }

    path = File.join('work', 'tmp')
    fn = File.join(path, 'pdef.rb')

    FileUtils.mkdir_p(path)
    File.open(fn, 'w') { |f| f.write(pdef) }

    assert_equal(
      ["define", {"name"=>"test"}, [["sequence", {}, [["echo", {"a"=>nil}, []], ["echo", {"b"=>nil}, []]]]]],
      @engine.load_definition(fn))
  end

  def test_load_illegal_definition

    pdef = %{
Ruote.process_definition :name => 'test' do
  exit
end
    }

    path = File.join('work', 'tmp')
    fn = File.join(path, 'pdef.rb')

    FileUtils.mkdir_p(path)
    File.open(fn, 'w') { |f| f.write(pdef) }

    assert_raise ArgumentError do
      @engine.load_definition(fn)
    end
  end
end

