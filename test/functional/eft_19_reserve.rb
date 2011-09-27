
#
# testing ruote
#
# Fri Jul 31 21:44:04 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftReserveTest < Test::Unit::TestCase
  include FunctionalBase

  def test_reserve

    pdef = Ruote.process_definition :name => 'test' do
      concurrence do
        reserve :mutex => 'a' do
          alpha
        end
        reserve 'a' do
          alpha
        end
      end
    end

    #noisy

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_equal '0_0_0_0', alpha.first.fei.expid

    ps = @dashboard.process(wfid)

    assert_equal 2, ps.variables.size

    assert_equal(
      [ 'mutex', 'a' ], ps.variables['a'][0, 2])
    assert_equal(
      [ '0_0_0', '0_0_1' ],
      ps.variables['a'].last.collect { |e| e['expid'] })

    alpha.proceed(alpha.first)

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_equal '0_0_1_0', alpha.first.fei.expid

    alpha.proceed(alpha.first)

    wait_for(wfid)
  end

  def test_cancel_reserve

    pdef = Ruote.process_definition :name => 'test' do
      concurrence do
        reserve :mutex => 'a' do
          alpha
        end
        reserve 'a' do
          alpha
        end
      end
    end

    #noisy

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    ps = @dashboard.process(wfid)
    exp = ps.expressions.find { |e| e.fei.expid == '0_0_0' }

    @dashboard.cancel_expression(exp.fei)

    wait_for(:alpha)

    #alpha.instance_variable_get(:@items).each { |i| p i }

    assert_equal 1, alpha.size
    assert_equal '0_0_1_0', alpha.first.fei.expid

    alpha.proceed(alpha.first)

    wait_for(wfid)
  end

  def test_reserve_but_no_name

    pdef = Ruote.process_definition :name => 'test' do
      concurrence do
        reserve do
          alpha
        end
        reserve do
          alpha
        end
      end
    end

    #noisy

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    2.times do

      wait_for(:alpha)

      assert_equal 1, alpha.size

      ps = @dashboard.process(wfid)

      assert_equal 2, ps.variables.size
      assert_not_nil ps.variables['reserve']

      alpha.proceed(alpha.first)
    end

    wait_for(wfid)
  end
end

