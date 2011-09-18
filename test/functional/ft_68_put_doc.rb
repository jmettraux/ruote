
#
# testing ruote
#
# Fri Sep 16 08:35:21 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtPutDocTest < Test::Unit::TestCase
  include FunctionalBase

  def test_put_doc

    #@engine.noisy = true

    @engine.storage.put_msg(
      'put_doc',
      'doc' => {
        'type' => 'variables',
        '_id' => 'variables',
        'variables' => { 'hello' => 'world' }
      })
    @engine.wait_for(1)

    assert_equal 'world', @engine.variables['hello']
  end

  def test_re_put_doc

    #@engine.noisy = true

    @engine.variables['hello'] = 'world'

    @engine.storage.put_msg(
      'put_doc',
      'doc' => {
        'type' => 'variables',
        '_id' => 'variables',
        'variables' => { 'hello' => 'Welt' }
      })
    @engine.wait_for(1)

    assert_equal 'Welt', @engine.variables['hello']
  end
end

