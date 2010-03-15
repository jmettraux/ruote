
#
# testing ruote
#
# Wed Jun 10 22:57:18 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtDollarTest < Test::Unit::TestCase
  include FunctionalBase

  def test_default

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'x', :val => 'variable'
        set :field => 'x', :val => 'field'
        echo '${x}'
      end
    end

    #noisy

    assert_trace 'field', pdef
  end

  def test_v

    pdef = Ruote.process_definition do
      sequence do
        echo 'a${v:missing}'
        set :var => 'v0', :val => '0'
        echo 'b${v:v0}'
        echo 'c${var:v0}'
        echo 'd${variable:v0}'
      end
    end

    #noisy

    assert_trace(%w[ a b0 c0 d0 ], pdef)
  end

  def test_nested_v

    pdef = Ruote.process_definition do
      sequence do
        set(
          :var => 'v0',
          :val => {
            'name' => 'toto',
            'address' => [ 'e-street', 'atlantic_city' ] })
        echo 'a:${v:v0.name}'
        echo 'b:${v:v0.address.1}'
      end
    end

    #noisy

    assert_trace(%w[ a:toto b:atlantic_city ], pdef)
  end

  def test_f

    pdef = Ruote.process_definition do
      sequence do
        set :field => 'f', :val => { 'name' => 'toto', 'address' => %w[ KL Asia ]}
        echo 'a${f:missing}'
        echo 'b${f:f.name}'
        echo 'c${f:f.address.1}'
      end
    end

    #noisy

    assert_trace(%w[ a btoto cAsia ], pdef)
  end

  def test_no_r

    pdef = Ruote.process_definition do
      sequence do
        echo '>${r:1 + 2}<'
      end
    end

    #noisy

    assert_trace('><', pdef)
  end

  def test_r

    pdef = Ruote.process_definition do
      sequence do
        echo '>${r:1 + 2}<'
      end
    end

    #noisy

    @engine.context['ruby_eval_allowed'] = true

    assert_trace('>3<', pdef)
  end

  def test_r_and_wi

    pdef = Ruote.process_definition do
      sequence do
        set 'f:toto' => 'person'
        echo "${r:wi.fields['toto']}"
        echo "${r:workitem.fields['toto']}"
      end
    end

    #noisy

    @engine.context['ruby_eval_allowed'] = true

    assert_trace "person\nperson", pdef
  end

  def test_r_and_d

    pdef = Ruote.process_definition do
      sequence do
        set 'f:toto' => 'person'
        echo "${r:d('f:toto')}"
      end
    end

    #noisy

    @engine.context['ruby_eval_allowed'] = true

    assert_trace 'person', pdef
  end

  def test_nested

    pdef = Ruote.process_definition do
      sequence do
        set 'f:a' => 'a'
        set 'v:a' => 'AA'
        echo '${v:${f:a}}'
      end
    end

    #noisy

    assert_trace 'AA', pdef
  end

  def test_wfid

    pdef = Ruote.process_definition do
      sequence do
        echo '${fei}'
        echo '${wfid}'
      end
    end

    wfid = @engine.launch(pdef)

    @engine.wait_for(wfid)

    assert_equal "0_0_0!!#{wfid}\n#{wfid}", @tracer.to_s
  end
end

