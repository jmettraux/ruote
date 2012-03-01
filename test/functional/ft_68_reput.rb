
#
# testing ruote
#
# Fri Sep 16 08:35:21 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtPutDocTest < Test::Unit::TestCase
  include FunctionalBase

  def test_reput_doc

    #@dashboard.noisy = true

    @dashboard.storage.put_msg(
      'reput',
      'doc' => {
        'type' => 'variables',
        '_id' => 'variables',
        'variables' => { 'hello' => 'world' }
      })
    @dashboard.wait_for(1)

    assert_equal 'world', @dashboard.variables['hello']
  end

  def test_re_reput_doc

    #@dashboard.noisy = true

    @dashboard.variables['hello'] = 'world'

    @dashboard.storage.put_msg(
      'reput',
      'doc' => {
        'type' => 'variables',
        '_id' => 'variables',
        'variables' => { 'hello' => 'Welt' }
      })
    @dashboard.wait_for(1)

    assert_equal 'Welt', @dashboard.variables['hello']
  end

  def test_reput_msg

    #@dashboard.noisy = true

    tree = Ruote.define do
      echo 'nada'
    end

    @dashboard.storage.put_msg(
      'reput',
      {
        'msg' => {
          'action' => 'launch',
          'tree' => tree,
          'put_at' => Time.now.to_s,
          'workitem' => { 'fields' => {} }
        }
      })

    @dashboard.wait_for('terminated')

    assert_equal 'nada', @tracer.to_s
  end
end

