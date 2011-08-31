
#
# testing ruote
#
# Mon Sep 14 08:39:35 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftCommandTest < Test::Unit::TestCase
  include FunctionalBase

  def test_ref_to_missing_tag

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        _break :ref => 'nemo'
        echo 'done.'
      end
    end

    #noisy

    assert_trace 'done.', pdef
  end
end

