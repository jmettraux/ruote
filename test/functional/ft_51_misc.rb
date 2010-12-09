
#
# testing ruote
#
# Thu Dec  9 16:39:54 JST 2010
#

require 'stringio'
require File.join(File.dirname(__FILE__), 'base')


class FtMiscTest < Test::Unit::TestCase
  include FunctionalBase

  def test_noisy

    result = String.new
    out = StringIO.new(result, 'w+')

    $stdout = out

    @engine.noisy = true

    wfid = @engine.launch(Ruote.define do
      echo 'nada'
    end)

    @engine.wait_for(wfid)

    out.close
    $stdout = STDOUT

    assert_not_nil result
  end
end

