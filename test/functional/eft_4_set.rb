
#
# testing ruote
#
# Wed May 20 09:23:01 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftSetTest < Test::Unit::TestCase
  include FunctionalBase

  def test_set_var

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'x', :value => '0'
        echo '-${v:x}-'
      end
    end

    #noisy

    assert_trace '-0-', pdef
  end

  def test_set_to_nil

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'x', :value => nil
        echo '-${v:x}-'
      end
    end

    #noisy

    assert_trace '--', pdef
  end

  def test_set_var_in_subprocess

    pdef = Ruote.process_definition do
      sequence do
        echo 'a${v:x}'
        set :var => 'x', :value => '0'
        echo 'b${v:x}'
        sub0
        echo 'e${v:x}'
      end
      define 'sub0' do
        sequence do
          echo 'c${v:x}'
          set :var => 'x', :value => '1'
          echo 'd${v:x}'
        end
      end
    end

    #noisy

    assert_trace %w[ a b0 c0 d1 e0 ], pdef
  end

  def test_unset_var

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'x', :value => '0'
        echo '-${v:x}-'
        unset :var => 'x'
        echo '-${v:x}-'
      end
    end

    #noisy

    assert_trace %w[ -0- -- ], pdef
  end

  def test_set_field

    pdef = Ruote.process_definition do
      sequence do
        set :field => 'f', :value => '0'
        echo '-${f:f}-'
      end
    end

    #noisy

    assert_trace '-0-', pdef
  end

  def test_set_field_to_array

    pdef = Ruote.process_definition do
      sequence do
        set :field => 'f', :value => %w[ a b c ]
        echo '-${f:f.1}-'
      end
    end

    #noisy

    assert_trace '-b-', pdef
  end

  def test_set_field_deep

    pdef = Ruote.process_definition do
      sequence do
        set :field => 'f', :value => %w[ a b c ]
        set :field => 'f.1', :val => 'B'
        echo '-${f:f.0}${f:f.1}${f:f.2}-'
      end
    end

    #noisy

    assert_trace '-aBc-', pdef
  end

  def test_missing_value

    pdef = Ruote.process_definition do
      set :field => 'f'
      alpha
    end

    @dashboard.register_participant :alpha do |workitem|
      workitem.fields.delete('params')
      workitem.fields.delete('dispatched_at')
      tracer << workitem.fields.inspect
    end

    assert_trace '{"f"=>nil}', pdef
  end

  def test_field_value

    pdef = Ruote.process_definition do
      sequence do
        set :f => 'f', :value => 'toto'
        set :v => 'v', :field_value => 'f'
        echo '${f:f}:${v:v}'
      end
    end

    #noisy

    assert_trace 'toto:toto', pdef
  end

  def test_escape

    pdef = Ruote.process_definition do
      sequence do
        set :f => 'f', :val => 'nada:${nada}', :escape => true
        alpha
        set :f => 'ff', :field_value => 'f'
        alpha
      end
    end

    @dashboard.register_participant :alpha do |workitem|
      tracer << workitem.fields['f'] + "\n"
    end

    #noisy

    assert_trace %w[ nada:${nada} nada:${nada} ], pdef
  end

  def test_simpler_set

    pdef = Ruote.process_definition do
      sequence do

        set 'f0' => '0'
        set 'f:f1' => '1'
        set 'v:v' => '2'
        echo '${f:f0}/${f:f1}/${v:v}'

        unset 'f0'
        unset 'f:f1'
        unset 'v:v'
        echo '${f:f0}/${f:f1}/${v:v}'
      end
    end

    #noisy

    assert_trace %w[ 0/1/2 // ], pdef
  end

  def test_simpler_and_nested

    pdef = Ruote.process_definition do
      sequence do
        set 'v:v' => '0'
        set 'v:v${v:v}' => 1
        echo '${v:v}/${v:v0}'
      end
    end

    #noisy

    assert_trace '0/1', pdef
  end

  def test_set_at_engine_level_is_forbidden

    pdef = Ruote.process_definition do
      set 'v://v' => 'whatever'
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)
    assert_nil @dashboard.variables['v']
  end

  # 'rset' is an alias for 'set'.
  #
  # motivation at http://groups.google.com/group/openwferu-users/browse_thread/thread/9ac606e30ada686e
  #
  def test_rset

    wfid = @dashboard.launch(Ruote.define do
      rset 'developer' => 'Rebo'
    end)

    r = @dashboard.wait_for(wfid)

    assert_equal 'Rebo', r['workitem']['fields']['developer']
  end

  def test_unset_field

    pdef = Ruote.define do

      set 'f:alpha' => 'alice'
      set 'f:bravo' => 'bob'
      set 'f:charly' => 'charles'
      set 'f:__timed_out__' => %w[ seriously ]
      set 'f:delta' => { 'echo' => 'e', 'foxtrott' => 'f' }

      unset 'f:alpha'
      unset :f => 'bravo'
      unset :field => 'charly'
      unset :field => '__timed_out__'
      unset 'f:delta.echo'
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal(
      { '__result__' => 'e', 'delta' => { 'foxtrott' => 'f' } },
      r['workitem']['fields'])
  end

  class VarPeek
    include Ruote::LocalParticipant
    def consume
      context.tracer << fexp.compile_variables.inspect
      reply
    end
  end

  def test_unset_var

    pdef = Ruote.define do
      set 'v:v0' => 'nada'
      set 'v:v1' => 'nada'
      unset 'v:v0'
      unset :v => 'v1'
      peek
    end

    @dashboard.register :peek, VarPeek

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal '{}', @tracer.to_s
  end

  def test_set_sets_return_field

    pdef = Ruote.define do
      set 'v:v0' => 'nada'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'nada', r['workitem']['fields']['__result__']
  end

  def test_set_picks_latest

    pdef = Ruote.define do
      set 'f0' do
        set 'v:v0' => '1'
        set 'v:v1' => '2'
        set 'f1' => '${v:v0}${v:v1}'
      end
      echo '${f0}/${v:v0}'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal '12', r['workitem']['fields']['f0']
    assert_equal '12/', @tracer.to_s
  end

  def test_set_if

    pdef = Ruote.define do
      set 'f:x' => '${v:v_r}', :if => '${v:v_r}'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal('terminated', r['action'])
    assert_equal({}, r['workitem']['fields'])
  end
end

