
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
      [ 'define', { 'name' => 'test' }, [
        ['sequence', {}, [
          ['echo', { 'a' => nil }, [] ],
          ['echo', { 'b' => nil}, [] ] ] ] ] ],
      @engine.load_definition(fn))
  end

  def test_load_definition_with_absolute_path

    pdef = %{
Ruote.process_definition do
  echo 'a'
end
    }

    path = File.join('work', 'tmp')
    fn = File.join(path, 'pdef.rb')

    FileUtils.mkdir_p(path)
    File.open(fn, 'w') { |f| f.write(pdef) }

    fn = File.expand_path(fn)

    assert_equal(
      [ 'define', {}, [ [ 'echo', { 'a' => nil }, [] ] ] ],
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

    assert_raise Ruote::Reader::Error do
      @engine.load_definition(fn)
    end
  end
end

