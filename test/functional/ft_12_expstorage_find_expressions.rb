
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

    #@verbose = true
    @verbose = false
    n = 10

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        participant :alpha
      end
    end

    sa = @engine.register_participant :alpha, OpenWFE::HashParticipant

    n.times { @engine.launch(pdef) }

    sleep 0.350
    sleep 0.350

    sto = @engine.get_expression_storage

    assert_find_count(41, {})

    # over.

    purge_engine
  end

  protected

  def assert_find_count (count, opts)

    t = Time.now
    c = @engine.get_expression_storage.find_expressions(opts).size
    t = (Time.now - t).to_f

    opts.delete(:cache)

    puts " .. #{opts.inspect} took #{t} ms" if @verbose

    assert_equal(count, c)
  end

end

