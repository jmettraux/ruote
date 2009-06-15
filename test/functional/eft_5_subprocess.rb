
#
# Testing Ruote (OpenWFEru)
#
# Wed May 20 17:08:17 JST 2009
#

require File.dirname(__FILE__) + '/base'


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

    assert_trace pdef, 'a'
  end

  def test_subprocess_att_text

    pdef = Ruote.process_definition do
      subprocess 'sub0'
      define :sub0 do
        echo 'a'
      end
    end

    #noisy

    assert_trace pdef, 'a'
  end

  def test_subprocess_exp_name

    pdef = Ruote.process_definition do
      sub0
      define :sub0 do
        echo 'a'
      end
    end

    #noisy

    assert_trace pdef, 'a'
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

    assert_trace pdef, %w[ a a ]
  end
end

