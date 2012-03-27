
#
# testing ruote
#
# Sun Aug 23 16:59:07 JST 2009
#

require File.expand_path('../base', __FILE__)


class FtVarIndirectionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_var_alias

    pdef = Ruote.process_definition :name => 'def0' do
      set :v => 'alpha', :val => 'bravo'
      sequence do
        alpha
        bravo
      end
    end

    alpha = @dashboard.register_participant :bravo do |workitem|
      tracer << "b:#{workitem.fields['params']['original_ref']}\n"
    end

    #noisy

    assert_trace(%w[ b:alpha b: ], pdef)
  end

  def test_participant_indirection

    pdef = Ruote.process_definition do
      sequence do
        set 'v:v' => 'alpha'
        #participant '${v:v}'
        v
      end
    end

    @dashboard.register_participant :alpha do |workitem|
      tracer << "alpha\n"
    end

    #noisy

    assert_trace 'alpha', pdef
  end

  def test_subprocess_indirection

    pdef = Ruote.process_definition do
      sequence do
        set 'v:v' => 'sub0'
        #subprocess '${v:v}'
        v
      end
      define 'sub0' do
        echo 'a'
      end
    end

    #noisy

    assert_trace 'a', pdef
  end

  def test_subprocess_indirection_uri

    pdef = Ruote.process_definition do
      sequence do
        set 'v:v' => File.join(File.dirname(__FILE__), '..', 'pdef.xml')
        #subprocess '${v:v}'
        v
      end
    end

    #noisy

    assert_trace %w[ a b ], pdef
  end

  def test_subprocess_uri_set_as_engine_variable

    pdef = Ruote.process_definition do
      v
    end

    #noisy

    @dashboard.variables['v'] = File.join(File.dirname(__FILE__), '..', 'pdef.xml')

    assert_trace %w[ a b ], pdef
  end

  def test_subprocess_uri_set_as_engine_variable__absolute

    pdef = Ruote.process_definition do
      v
    end

    #noisy

    @dashboard.variables['v'] = File.expand_path(
      File.join(File.dirname(__FILE__), '..', 'pdef.xml'))

    assert_trace %w[ a b ], pdef
  end

  def test_engine_variable_for_expression_aliases

    pdef = Ruote.define do
      output "nada"
    end

    @dashboard.variables['output'] = 'echo'

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 'nada', @tracer.to_s
  end
end

