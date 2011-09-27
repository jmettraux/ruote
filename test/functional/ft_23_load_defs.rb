
#
# testing ruote
#
# Wed Aug  5 08:35:38 JST 2009
#

require File.expand_path('../base', __FILE__)


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
      @dashboard.load_definition(fn))
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
      @dashboard.load_definition(fn))
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
      @dashboard.load_definition(fn)
    end
  end
end

