
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

    assert_trace pdef, 'field'
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

    assert_trace(pdef, %w[ a b0 c0 d0 ])
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

    assert_trace(pdef, %w[ a btoto cAsia ])
  end

  def test_no_r

    pdef = Ruote.process_definition do
      sequence do
        echo '>${r:1 + 2}<'
      end
    end

    #noisy

    assert_trace(pdef, '><')
  end

  def test_r

    pdef = Ruote.process_definition do
      sequence do
        echo '>${r:1 + 2}<'
      end
    end

    #noisy

    @engine.context[:ruby_eval_allowed] = true

    assert_trace(pdef, '>3<')
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

    @engine.context[:ruby_eval_allowed] = true

    assert_trace pdef, "person\nperson"
  end

  def test_r_and_d

    pdef = Ruote.process_definition do
      sequence do
        set 'f:toto' => 'person'
        echo "${r:d('f:toto')}"
      end
    end

    #noisy

    @engine.context[:ruby_eval_allowed] = true

    assert_trace pdef, 'person'
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

    assert_trace pdef, 'AA'
  end
end

