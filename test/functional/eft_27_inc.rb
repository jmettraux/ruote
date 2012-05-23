
#
# testing ruote
#
# Sat Sep 19 12:56:16 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftIncTest < Test::Unit::TestCase
  include FunctionalBase

  def test_inc

    pdef = Ruote.process_definition do
      sequence do

        set :var => 'x', :value => 0
        set :field => 'y', :value => 0

        inc 'v:x'
        inc 'f:y'
        inc :var => 'x'
        inc :field => 'y'

        echo '${v:x}|${f:y}'
      end
    end

    assert_trace '2|2', pdef
  end

  def test_inc_missing

    pdef = Ruote.process_definition do
      sequence do

        inc 'v:x'
        inc 'f:y'
        inc :var => 'x'
        inc :field => 'y'

        echo '${v:x}|${f:y}'
      end
    end

    assert_trace '2|2', pdef
  end

  def test_inc_delta

    pdef = Ruote.process_definition do
      sequence do

        inc 'v:x', :val => 2
        inc 'f:y', :val => 3
        inc 'v:z', :val => 1.0

        inc :var => 'x', :val => '4'
        inc :field => 'y', :val => 5
        inc 'v:z', :val => '2.0'

        inc 'v:x' => 2
        inc 'y' => 2
        inc 'v:z' => 0.5

        echo '${v:x}|${f:y}|${v:z}'
      end
    end

    assert_trace '8|10|3.5', pdef
  end

  def test_inc_v_val

    pdef = Ruote.process_definition do
      sequence do

        set 'v:x' => 2

        inc 'v:x', :v_val => 'x'

        echo '${v:x}'
      end
    end

    assert_trace '4', pdef
  end

  def test_inc_array

    @dashboard.context['ruby_eval_allowed'] = true

    pdef = Ruote.process_definition do
      sequence do

        set 'v:x' => %w[ alpha bravo ]

        inc 'v:x', :val => 'charly'

        echo '${r:fe.lv("x").join("\n")}'
      end
    end

    assert_trace %w[ alpha bravo charly ], pdef
  end

  def test_inc_array_head

    #@dashboard.context['ruby_eval_allowed'] = true
    @dashboard.configure('ruby_eval_allowed', true)

    pdef = Ruote.process_definition do
      sequence do

        set 'v:x' => %w[ alpha bravo ]

        inc 'v:x', :val => 'charly', :pos => :head

        echo '${r:fe.lv("x").join("\n")}'
      end
    end

    assert_trace %w[ charly alpha bravo ], pdef
  end

  def test_inc_array_missing

    @dashboard.context['ruby_eval_allowed'] = true

    pdef = Ruote.process_definition do
      sequence do

        inc 'v:x', :val => 'charly'
        inc 'v:y', :val => 'charly', :pos => :head

        echo '${r:fe.lv("x").join(".")}'
        echo '${r:fe.lv("y").join(".")}'
      end
    end

    assert_trace %w[ charly charly ], pdef
  end

  def test_dec

    pdef = Ruote.process_definition do
      sequence do

        set :var => 'x', :value => 4
        set :field => 'y', :value => 4

        dec 'v:x'
        dec 'f:y'
        dec 'v:z'

        echo '${v:x}|${f:y}|${v:z}'
      end
    end

    assert_trace '3|3|-1', pdef
  end

  def test_dec_array

    @dashboard.context['ruby_eval_allowed'] = true

    pdef = Ruote.define do

      set 'v:x' => %w[ a b c ]
      set 'v:y' => %w[ d e f ]

      dec 'v:x'
      dec 'v:y', :position => :head

      echo '${r:fe.lv("x").join(".")}'
      echo '${r:fe.lv("y").join(".")}'
      echo '${__result__}'
    end

    assert_trace %w[ a.b e.f d ], pdef
  end

  def test_dec_val

    @dashboard.context['ruby_eval_allowed'] = true

    pdef = Ruote.define do

      set 'v:x' => %w[ a b c ]

      dec 'v:x', :val => 'b'

      echo '${r:fe.lv("x").join(".")}'
      echo '${__result__}'
    end

    assert_trace %w[ a.c b ], pdef
  end

  def test_dec_val_to_d

    @dashboard.context['ruby_eval_allowed'] = true

    pdef = Ruote.define do

      set 'v:x' => %w[ a b c ]

      dec 'v:x', :val => 'b', :to_v => 'd'

      echo '${r:fe.lv("x").join(".")}'
      echo '${v:d}'
    end

    assert_trace %w[ a.c b ], pdef
  end

  def test_cursor

    pdef = Ruote.process_definition do
      sequence do
        set 'v:x' => %w[ a b c d ]
        repeat do
          dec 'v:x', :pos => :head
          echo '${__result__}'
          _break :unless => '${__result__}'
        end
      end
    end

    assert_trace %w[ a b c d ], pdef
  end

  def test_bare_inc

    pdef = Ruote.process_definition do
      sequence do
        inc
        echo 'done.'
      end
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size
  end

  def test_nested_inc

    pdef = Ruote.define do

      set :var => 'x', :value => 1

      inc 'v:x' do
        set '__result__' => 2
      end

      echo '${v:x}'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal '3', @tracer.to_s
  end

  def test_push

    pdef = Ruote.define do
      push 'v:x' => 1
      push 'v:x' => 2
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal [ 1, 2 ], r['variables']['x']
  end

  def test_pop

    pdef = Ruote.define do
      pop 'v:x'
      push 'v:x' => false
      push 'v:x' => 1
      push 'v:x' => 2
      pop 'v:x'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal [ false, 1 ], r['variables']['x']
    assert_equal 2, r['workitem']['fields']['__result__']
  end

  def test_pop_2

    pdef = Ruote.define do

      set 'v:x' => 12
      push 'v:x' => 4
      pop 'v:x'

      pop 'v:y'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal [ 12 ], r['variables']['x']
    assert_equal [], r['variables']['y']
  end
end

