
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

  def test_vars_to_f

    pdef = Ruote.define do
      sequence :vars_to_f => 'f0' do
        set 'v:v0' => 'x'
      end
      sequence :vars_to_f => 'f1', :scope => true do
        set 'v:v1' => 'y'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal(
      { 'f0' => nil, 'f1' => { 'v1' => 'y' }, '__result__' => 'y' },
      r['workitem']['fields'])
  end
end

