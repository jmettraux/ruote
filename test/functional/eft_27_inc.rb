
#
# testing ruote
#
# Sat Sep 19 12:56:16 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


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

    #noisy

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

    #noisy

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

        echo '${v:x}|${f:y}|${v:z}'
      end
    end

    #noisy

    assert_trace '6|8|3.0', pdef
  end

  def test_inc_v_val

    pdef = Ruote.process_definition do
      sequence do

        set 'v:x' => 2

        inc 'v:x', :v_val => 'x'

        echo '${v:x}'
      end
    end

    #noisy

    assert_trace '4', pdef
  end

  def test_inc_array

    @engine.context['ruby_eval_allowed'] = true

    pdef = Ruote.process_definition do
      sequence do

        set 'v:x' => %w[ alpha bravo ]

        inc 'v:x', :val => 'charly'

        echo '${r:fe.lv("x").join("\n")}'
      end
    end

    #noisy

    assert_trace %w[ alpha bravo charly ], pdef
  end

  def test_inc_array_head

    #@engine.context['ruby_eval_allowed'] = true
    @engine.configure('ruby_eval_allowed', true)

    pdef = Ruote.process_definition do
      sequence do

        set 'v:x' => %w[ alpha bravo ]

        inc 'v:x', :val => 'charly', :pos => :head

        echo '${r:fe.lv("x").join("\n")}'
      end
    end

    #noisy

    assert_trace %w[ charly alpha bravo ], pdef
  end

  def test_inc_array_missing

    @engine.context['ruby_eval_allowed'] = true

    pdef = Ruote.process_definition do
      sequence do

        inc 'v:x', :val => 'charly'
        inc 'v:y', :val => 'charly', :pos => :head

        echo '${r:fe.lv("x").join(".")}'
        echo '${r:fe.lv("y").join(".")}'
      end
    end

    #noisy

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

    #noisy

    assert_trace '3|3|-1', pdef
  end

  def test_dec_array

    @engine.context['ruby_eval_allowed'] = true

    pdef = Ruote.process_definition do
      sequence do

        set 'v:x' => %w[ a b c ]
        set 'v:y' => %w[ a b c ]

        dec 'v:x'
        dec 'v:y', :position => :head

        echo '${r:fe.lv("x").join(".")}'
        echo '${r:fe.lv("y").join(".")}'
        echo '${v:d}'
      end
    end

    #noisy

    assert_trace %w[ a.b b.c a ], pdef
  end

  def test_dec_to

    @engine.context['ruby_eval_allowed'] = true

    pdef = Ruote.process_definition do
      sequence do

        set 'v:x' => %w[ a b c ]

        dec 'v:x', :to_var => 'y'

        echo '${r:fe.lv("x").join(".")}'
        echo '${v:y}'
      end
    end

    #noisy

    assert_trace %w[ a.b c ], pdef
  end

  def test_dec_val

    @engine.context['ruby_eval_allowed'] = true

    pdef = Ruote.process_definition do
      sequence do

        set 'v:x' => %w[ a b c ]

        dec 'v:x', :val => 'b'

        echo '${r:fe.lv("x").join(".")}'
        echo '${v:d}'
      end
    end

    #noisy

    assert_trace %w[ a.c b ], pdef
  end

  def test_cursor

    pdef = Ruote.process_definition do
      sequence do
        set 'v:x' => %w[ a b c d ]
        repeat do
          dec 'v:x', :pos => :head
          _break :unless => '${v:d}'
          echo '${v:d}'
        end
      end
    end

    #noisy

    assert_trace %w[ a b c d ], pdef
  end

  def test_bare_inc

    pdef = Ruote.process_definition do
      sequence do
        inc
        echo 'done.'
      end
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size
  end
end

