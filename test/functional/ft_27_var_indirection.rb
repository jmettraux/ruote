
#
# testing ruote
#
# Sun Aug 23 16:59:07 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtVarIndirectionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant_indirection

    pdef = Ruote.process_definition do
      sequence do
        set 'v:v' => 'alpha'
        #participant '${v:v}'
        v
      end
    end

    @engine.register_participant :alpha do |workitem|
      @tracer << "alpha\n"
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

    @engine.variables['v'] = File.join(File.dirname(__FILE__), '..', 'pdef.xml')

    assert_trace %w[ a b ], pdef
  end

  def test_subprocess_uri_set_as_engine_variable__absolute

    pdef = Ruote.process_definition do
      v
    end

    #noisy

    @engine.variables['v'] = File.expand_path(
      File.join(File.dirname(__FILE__), '..', 'pdef.xml'))

    assert_trace %w[ a b ], pdef
  end
end

