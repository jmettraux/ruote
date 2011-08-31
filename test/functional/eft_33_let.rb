
#
# testing ruote
#
# Fri Dec 24 15:35:17 JST 2010
#

require File.expand_path('../base', __FILE__)


class EftLetTest < Test::Unit::TestCase
  include FunctionalBase

  def test_let

    pdef = Ruote.process_definition do
      set 'v:var' => 'val'
      echo "out:${v:var}"
      let do
        set 'v:var' => 'val1'
        echo "in:${v:var}"
      end
      echo "out:${v:var}"
    end

    #noisy

    assert_trace %w[ out:val in:val1 out:val ], pdef
  end
end

