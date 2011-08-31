
#
# testing ruote
#
# Sat Oct 23 14:22:15 JST 2010
#

require File.expand_path('../base', __FILE__)


class FtWfidGeneratorTest < Test::Unit::TestCase
  include FunctionalBase

  # an old test, brought back
  #
  def test_generate_unique_ids

    n = 147

    wfids = []
    n.times { wfids << @engine.context.wfidgen.generate }

    assert_equal n, wfids.uniq.size
  end

  # making a purge! doesn't incapacitate wfid generation
  # (had a false alert when working with @hassox)
  #
  def test_generate_even_after_a_purge

    assert_not_nil @engine.context.wfidgen.generate

    @engine.storage.purge!
    #@engine.context.wfidgen.instance_eval { @last = nil }

    assert_not_nil @engine.context.wfidgen.generate
  end

  def test_generate_after_a_put_failed

    assert_not_nil @engine.context.wfidgen.generate

    @engine.context.wfidgen.instance_eval do
      if @last['_rev'].is_a?(String)
        @last['_rev'] = '1-cc9bc774f00b65ee28a6c0e4f26474de'
      else # integer
        @last['_rev'] = 123456789
      end
    end

    assert_not_nil @engine.context.wfidgen.generate
  end
end

