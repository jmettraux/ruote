
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Mar 31 22:22:06 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/participants/store_participants'


class FtFindExpressions < Test::Unit::TestCase
  include FunctionalBase

  def test_find_expressions

    @verbose = false
    #@verbose = true

    n = 21

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        participant :alpha
      end
    end

    sa = @engine.register_participant :alpha, OpenWFE::HashParticipant

    fei = nil
    n.times { fei = @engine.launch(pdef) }

    sleep 0.350
    sleep 0.350
    sleep 0.350 # ar_expstorage is not very fast :( wait fail

    assert_find_count(n * 4 + 1, {})
    assert_find_count(n, :workitem => true)
    assert_find_count(4, :wfid => fei.wfid)

    # over.

    purge_engine
  end

  def test_find_schedulable_expressions

    @verbose = false
    #@verbose = true

    n = 21

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        wait '3w'
      end
    end

    fei = nil
    n.times { fei = @engine.launch(pdef) }

    sleep 0.350
    sleep 0.350
    sleep 0.350 # ar_expstorage is not very fast :( wait fail

    assert_find_count(2 * n + 1, { :include_classes => Rufus::Schedulable })
      # environments are schedulable

    # over.

    purge_engine
  end

  protected

  def assert_find_count (count, opts)

    o = opts.dup

    t = Time.now
    c = @engine.get_expression_storage.find_expressions(opts).size
    t = (Time.now - t).to_f

    o.delete(:cache)

    puts " .. #{o.inspect} took #{t} ms" if @verbose

    assert_equal(count, c)
  end

end

