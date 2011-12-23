
#
# testing ruote
#
# Fri Dec 23 14:11:13 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtScopeTest < Test::Unit::TestCase
  include FunctionalBase


  def test_let_like

    pdef = Ruote.process_definition do
      set 'v:var' => 'val'
      echo "out:${v:var}"
      sequence :scope => true do
        set 'v:var' => 'val1'
        echo "in:${v:var}"
      end
      echo "out:${v:var}"
    end

    #noisy

    assert_trace %w[ out:val in:val1 out:val ], pdef
  end
end

