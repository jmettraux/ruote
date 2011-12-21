
#
# testing ruote
#
# Wed May 20 17:08:17 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftSubprocessTest < Test::Unit::TestCase
  include FunctionalBase

  def test_subprocess_ref

    pdef = Ruote.process_definition do
      subprocess :ref => 'sub0'
      define :sub0 do
        echo 'a'
      end
    end

    #noisy

    assert_trace 'a', pdef
  end

  def test_subprocess_att_text

    pdef = Ruote.process_definition do
      subprocess 'sub0'
      define :sub0 do
        echo 'a'
      end
    end

    #noisy

    assert_trace 'a', pdef
  end

  def test_subprocess_exp_name

    pdef = Ruote.process_definition do
      sub0
      define :sub0 do
        echo 'a'
      end
    end

    #noisy

    assert_trace 'a', pdef
  end

  def test_subprocess_if

    pdef = Ruote.process_definition do
      define :sub0 do
        echo 'a'
      end
      sequence do
        subprocess :ref => 'sub0'
        subprocess :ref => 'sub0', :if => 'true == false'
        subprocess :ref => 'sub0'
      end
    end

    #noisy

    assert_trace %w[ a a ], pdef
  end

  def test_subprocess_atts_to_vars

    pdef = Ruote.process_definition do
      subprocess 'sub0', :a => 'A', :b => 'B'
      define :sub0 do
        echo '${v:a}:${v:b}'
      end
    end

    #noisy

    assert_trace 'A:B', pdef
  end

  def test_subprocess_passing_tree

    pdef = Ruote.process_definition do
      subprocess 'sub0' do
        noop
      end
      define :sub0 do
        alpha
      end
    end

    @dashboard.register_participant :alpha do |workitem, fexp|
      stash[:tree] = fexp.lookup_variable('tree')
    end

    #noisy

    assert_trace '', pdef

    assert_equal ["noop", {}, []], stash[:tree]
  end

  def test_subprocess_uri

    pdef = Ruote.process_definition do
      sequence do
        echo 'in'
        subprocess :ref => File.join(File.dirname(__FILE__), '..', 'pdef.xml')
        echo 'out.'
      end
    end

    #noisy

    assert_trace %w[ in a b out. ], pdef
  end

  def test_missing_uri

    pdef = Ruote.process_definition do
      sequence do
        echo 'in'
        subprocess :ref => 'nada'
        echo 'out.'
      end
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    assert_equal(
      "#<RuntimeError: no subprocess named 'nada' found>",
      #"#<RuntimeError: unknown participant or subprocess 'nada'>",
      @dashboard.process(wfid).errors.first.message)
  end

  def test_subprocess_in_engine_variable

    pdef = Ruote.process_definition do
      sequence do
        sub0
        echo 'done.'
      end
    end

    @dashboard.variables['sub0'] = Ruote.process_definition do
      echo 'in sub0'
    end

    assert_trace "in sub0\ndone.", pdef
  end

  def test_atts_to_fields

    pdef = Ruote.define do
      set 'address' => { 'city' => 'boston' }
      subprocess(
        'sub0',
        'f:a' => 'fa',
        'field:b' => 'mi',
        'var:c' => 'sol',
        'f:address.city' => 'nyc')
      define 'sub0' do
        echo '${a} ${b} ${v:c} ${address.city}'
      end
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'fa mi sol nyc', @tracer.to_s
  end
end

