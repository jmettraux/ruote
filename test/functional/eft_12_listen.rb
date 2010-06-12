
#
# testing ruote
#
# Fri Jun 19 15:26:33 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class EftListenTest < Test::Unit::TestCase
  include FunctionalBase

  def test_listen

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          listen :to => '^al.*'
          echo '1'
        end
        sequence do
          alpha
        end
      end
    end

    #noisy

    @engine.register_participant :alpha do
      @tracer << "alpha\n"
    end

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    assert_equal %w[ 1 alpha ], @tracer.to_a.sort

    assert_equal(
      0, @engine.context.storage.get('variables', 'trackers')['trackers'].size)
  end

  def test_listen_with_child

    pdef = Ruote.process_definition do
      concurrence do
        listen :to => '^al.*' do
          bravo
        end
        sequence do
          alpha
          alpha
        end
      end
    end

    @engine.register_participant :alpha do
      @tracer << "a\n"
    end
    @engine.register_participant :bravo do |workitem|
      @tracer << "#{workitem.fei.wfid}|#{workitem.fei.sub_wfid}"
      @tracer << "\n"
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:bravo)
    wait_for(:bravo)
    wait_for(2)

    sleep 0.001

    #p @tracer.to_s

    a = @tracer.to_a
    assert_equal 2, a.select { |e| e == 'a' }.size

    a = (a - [ 'a', 'a' ]).sort
    assert_equal 2, a.uniq.size

    ps = @engine.process(wfid)

    #assert_equal 3, ps.expressions.size
    assert_equal 0, ps.errors.size

    assert_equal(
      1, @engine.context.storage.get('variables', 'trackers')['trackers'].size)
  end

  def test_upon

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          listen :to => '^al.*', :merge => false
          bravo
        end
        sequence do
          listen :to => '^al.*', :upon => 'reply'
          bravo
        end
        sequence do
          alpha
        end
      end
    end

    #noisy

    @engine.register_participant :alpha do |workitem|
      @tracer << "alpha\n"
      workitem.fields['seen'] = 'yes'
    end
    @engine.register_participant :bravo do |workitem|
      @tracer << "bravo:#{workitem.fields['seen']}\n"
    end

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal %w[ alpha bravo: bravo:yes ], @tracer.to_a.sort
  end

  def test_merge_override

    pdef = Ruote.process_definition do
      set :f => 'name', :val => 'Kilroy'
      set :f => 'other', :val => 'nothing'
      concurrence do
        sequence do
          listen :to => '^al.*', :merge => 'override', :upon => 'reply'
          bravo
        end
        sequence do
          alpha
        end
      end
    end

    #noisy

    @engine.register_participant :alpha do |wi|
      @tracer << "alpha\n"
      wi.fields['name'] = 'William Mandella'
    end
    @engine.register_participant :bravo do |wi|
      @tracer << "name:#{wi.fields['name']} "
      @tracer << "other:#{wi.fields['other']}\n"
    end

    assert_trace("alpha\nname:William Mandella other:nothing", pdef)
  end

  def test_where

    pdef = Ruote.process_definition do
      concurrence do
        listen :to => 'alpha', :where => '${f:who} == toto', :upon => 'reply' do
          echo 'toto'
        end
        sequence do
          alpha
        end
        sequence do
          alpha
        end
      end
    end

    #noisy

    count = 0

    @engine.register_participant :alpha do |wi|
      @tracer << "alpha\n"
      wi.fields['who'] = 'toto' if count > 0
      count = count + 1
    end

    wfid = @engine.launch(pdef)

    wait_for(wfid) # ceased

    assert_equal %w[ alpha alpha toto ].join("\n"), @tracer.to_s
    assert_equal 3, @engine.process(wfid).expressions.size
    assert_equal 'ceased', @engine.context.logger.log.last['action']
  end

  def test_listen_cancel

    pdef = Ruote.process_definition do
      listen :to => 'alpha'
    end

    wfid = @engine.launch(pdef)

    wait_for(2)

    assert_equal(
      1, @engine.context.storage.get('variables', 'trackers')['trackers'].size)

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_equal(
      0, @engine.context.storage.get('variables', 'trackers')['trackers'].size)
  end

  def test_cross

    listening = Ruote.process_definition do
      sequence do
        listen :to => 'alpha'
        echo 'ldone.'
      end
    end
    emitting = Ruote.process_definition do
      sequence do
        alpha
        echo 'edone.'
      end
    end

    @engine.register_participant :alpha do
      # nothing
    end

    #noisy

    lwfid = @engine.launch(listening)
    ewfid = @engine.launch(emitting)

    wait_for(lwfid, ewfid)

    #assert_equal("edone.\nldone.", @tracer.to_s)
    assert_equal %w[ edone. ldone. ], @tracer.to_a.sort
  end

  def test_not_cross

    listening = Ruote.process_definition do
      sequence do
        listen :to => 'alpha', :wfid => :same
        echo 'ldone.'
      end
    end
    emitting = Ruote.process_definition do
      sequence do
        alpha
        echo 'edone.'
      end
    end

    @engine.register_participant :alpha do
      # nothing
    end

    lwfid = @engine.launch(listening)
    ewfid = @engine.launch(emitting)

    wait_for(ewfid)

    assert_equal("edone.", @tracer.to_s)

    ps = @engine.process(lwfid)
    assert_equal(3, ps.expressions.size)
  end
end

