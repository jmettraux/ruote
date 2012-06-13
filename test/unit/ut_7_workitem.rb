
#
# testing ruote
#
# Mon Jun 15 16:43:06 JST 2009
#


require File.expand_path('../../test_helper', __FILE__)

#require_json
require 'rufus-json/automatic'

require 'ruote/fei'
require 'ruote/workitem'


class UtWorkitemTest < Test::Unit::TestCase

  def test_equality

    f0 = { 'expid' => '0', 'wfid' => '20101224-baba', 'engine_id' => 'engine' }
    f1 = { 'expid' => '0', 'wfid' => '20101224-baba', 'engine_id' => 'engine' }
    f2 = { 'expid' => '1', 'wfid' => '20101224-baba', 'engine_id' => 'engine' }

    w0 = Ruote::Workitem.new('fei' => f0, 'fields' => { 'a' => 'A' })
    w1 = Ruote::Workitem.new('fei' => f1, 'fields' => { 'b' => 'B' })
    w2 = Ruote::Workitem.new('fei' => f2, 'fields' => { 'c' => 'C' })

    assert w0 == w1
    assert w0 != w2

    assert_equal w0.hash, w1.hash
    assert_not_equal w0.hash, w2.hash
  end

  def test_lookup

    w0 = Ruote::Workitem.new(
      'fields' => {
        'customer' => {
          'name' => 'Jeff',
          'address' => [ 'Cornwall Square 10', 'Singapore-La' ] } })

    assert_equal 'Jeff', w0.lookup('customer.name')
    assert_equal 'Singapore-La', w0.lf('customer.address.1')

    w0.set_field('customer.address', [ 'Cornwall Square 10b', 'Singapore-La' ])
    assert_equal 'Cornwall Square 10b', w0.lookup('customer.address.0')

    assert_equal 'Jeff', w0['customer.name']

    w0['customer.address'] = [ 'hondouri', 'hiroshima' ]
    assert_equal 'hiroshima', w0['customer.address.1']
  end

  #def test_indifferent_access
  #  w0 = Ruote::Workitem.new(
  #    'fields' => { 'customer' => 'john' })
  #  assert_equal 'john', w0.fields['customer']
  #  assert_equal 'john', w0.fields[:customer]
  #end

  def test_sid

    f0 = { 'expid' => '0', 'wfid' => '20101224-baba', 'engine_id' => 'engine' }
    w0 = Ruote::Workitem.new('fei' => f0, 'fields' => { 'a' => 'A' })

    assert_equal '0!!20101224-baba', w0.sid
  end

  def test_wfid

    f0 = { 'expid' => '0', 'wfid' => '20101224-baba', 'engine_id' => 'engine' }
    w0 = Ruote::Workitem.new('fei' => f0, 'fields' => { 'a' => 'A' })

    assert_equal '20101224-baba', w0.wfid
  end

  def test_command

    wi = Ruote::Workitem.new(
      'fei' => 'x', 'fields' => { '__command__' => %w[ jump shark ] })

    assert_equal %w[ jump shark ], wi.command
  end

  WI = {
    'fei' => {
      'expid' => '0',
      'wfid' => '20101224-baba',
      'engine_id' => 'engine',
      'subid' => '123423fde6' },
    'participant_name' => 'john',
    'fields' => {
      'customer' => 'swissre'
    }
  }
  WI_JSON = ::Rufus::Json.encode(WI)
  WI_PRETTY_JSON = ::Rufus::Json.pretty_encode(WI)

  def test_from_json

    assert_equal WI, Ruote::Workitem.from_json(WI_JSON).h
    assert_equal WI, Ruote::Workitem.from_json(WI_PRETTY_JSON).h
  end

  def test_as_json

    assert_equal WI, Rufus::Json.decode(Ruote::Workitem.new(WI).as_json)
  end
end

