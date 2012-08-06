
#
# testing ruote
#
# Sat Jan  7 15:23:56 JST 2012
#

require File.expand_path('../base', __FILE__)


class EftAwaitTest < Test::Unit::TestCase
  include FunctionalBase

  def test_await_tag

    pdef = Ruote.process_definition do
      concurrence :wait_for => 4 do
        sequence do
          await :left_tag => 'alpha'
          echo 'a0'
        end
        sequence do
          await :entered_tag => 'alpha'
          echo 'a1'
        end
        sequence do
          await :entered_tag => /pha$/
          echo 'a2'
        end
        sequence do
          await :tags => 'alpha'
          echo 'a3'
        end
        sequence do
          await :entered_tag => /pha./
          echo 'a9'
        end
        sequence do
          noop # skip a beat
          sequence :tag => 'alpha' do
            echo 'alpha'
          end
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal %w[ a0 a1 a2 a3 alpha ], @tracer.to_a.sort

    assert @tracer.to_a.index('a1') < @tracer.to_a.index('a0')
  end

  def test_await_participant

    @dashboard.register 'a' do
      tracer << "a\n"
    end

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          await :reached_participant => 'a'
          echo 'b'
        end
        sequence do
          await :left_participant => 'a'
          echo 'c'
        end
        sequence do
          noop # skip a beat
          participant 'a'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 3, @tracer.to_a.size
    assert_equal 3, @tracer.to_a.uniq.size
    assert_equal 'c', @tracer.to_a.last
  end

  def test_tag_or_tag

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          await :left_tag => 'a, b'
          echo 'ab'
        end
        sequence do
          await :left_tag => %w[ c d ]
          echo 'cd'
        end
        sequence do
          noop # skip a beat
          concurrence do
            echo 'a', :tag => 'a'
            echo 'c', :tag => 'c'
          end
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal %w[ a ab c cd ], @tracer.to_a.sort
  end

  def test_absolute_tag

    pdef = Ruote.define do
      concurrence do
        sequence do
          await :tags => 'a/b'
          echo 'a/b'
        end
        sequence :tag => 'a' do
          noop
          sequence :tag => 'b' do
            echo 'b'
          end
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal %w[ a/b b ], @tracer.to_a.sort
  end

  def test_error

    pdef = Ruote.process_definition do
      concurrence :wait_for => 4 do
        sequence do
          await :error => /na(d|f)a/
          echo 'e0'
        end
        sequence do
          await :error => 'nada'
          echo 'e1'
        end
        sequence do
          await :error => 'Ruote::ForcedError, ArgumentError'
          echo 'e2'
        end
        sequence do
          await 'error'
          echo 'e3'
        end
        sequence do
          noop # skip a beat
          error 'nada'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for('terminated')

    assert_equal %w[ e0 e1 e2 e3 ], @tracer.to_a.sort
  end

  def test_where

    @dashboard.register 'a' do |workitem|
      workitem['task'] = workitem.params['task']
    end

    pdef = Ruote.define do
      concurrence :wait_for => 1 do
        await :left_participant => 'a', :where => "${task} == 'sing'" do
          echo 'sing-a'
        end
        await :left_participant => 'a' do
          echo 'any-a'
        end
        concurrence do
          participant 'a', :task => 'talk'
          participant 'a', :task => 'sing'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for('terminated')

    assert_equal %w[ any-a any-a sing-a ], @tracer.to_a.sort
  end

  def test_implicit_sequence

    @dashboard.register 'a' do |workitem|
    end

    pdef = Ruote.define do
      concurrence :wait_for => 1 do
        await :left_participant => 'a' do
          echo 'a0'
          echo 'a1'
        end
        sequence do
          participant 'a'
          noop; noop; noop # give time to concurrent branch to reach a1
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for('terminated')

    assert_equal %w[ a0 a1 ], @tracer.to_a.sort
  end

  def test_other_process

    wfid = @dashboard.launch(Ruote.define do
      await :tags => 'a'
      echo 'local' # shouldn't happen
    end)
    @dashboard.launch(Ruote.define do
      await :tags => 'a', :global => true
      echo 'global'
    end)
    @dashboard.launch(Ruote.define do
      noop; noop # making sure the 'awaits' are in place
      noop :tag => 'a'
    end)

    @dashboard.wait_for('terminated')
    @dashboard.wait_for('terminated')

    assert_equal %w[ global ], @tracer.to_a.sort
    assert_not_nil @dashboard.ps(wfid)
  end

  def test_merge

    # override / ignore / incoming / awaiting

    pdef = Ruote.define do

      set 'customer' => 'bamboku'
      set 'city' => 'kyouto'

      concurrence do

        sequence do
          await :in_tag => 'alpha'
          echo 'a:${customer}/${city}/${region}'
        end
        sequence do
          await :in_tag => 'alpha', :merge => 'override'
          echo 'b:${customer}/${city}/${region}'
        end
        sequence do
          await :in_tag => 'alpha', :merge => 'ignore'
          echo 'c:${customer}/${city}/${region}'
        end
        sequence do
          await :in_tag => 'alpha', :merge => 'incoming'
          echo 'd:${customer}/${city}/${region}'
        end
        sequence do
          await :in_tag => 'alpha', :merge => 'awaiting'
          echo 'e:${customer}/${city}/${region}'
        end

        sequence do
          4.times { noop } # making sure the 'awaits' are in place
          set 'customer' => 'antoku'
          unset 'city'
          set 'region' => 'fukuhara'
          noop :tag => 'alpha'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal %w[
      a:antoku//fukuhara
      b:antoku//fukuhara
      c:bamboku/kyouto/
      d:antoku/kyouto/fukuhara
      e:bamboku/kyouto/fukuhara
    ], @tracer.to_a.sort
  end
end

