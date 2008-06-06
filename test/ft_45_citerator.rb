
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest45 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  class TestCase45a0 < OpenWFE::ProcessDefinition
    sequence do
      concurrent_iterator :on_value => "1, 2", :to_variable => "v" do
        _print "${r:fei.expid} - ${v}"
      end
      _print "done."
    end
  end

  def test_0
    dotest(
      TestCase45a0,
      [ """
0.0.0.0 - 1
0.0.0.1 - 2
done.
        """.strip,
        """
0.0.0.1 - 2
0.0.0.0 - 1
done.
        """.strip
      ])
  end


  #
  # Test 1
  #

  class TestCase45a1 < OpenWFE::ProcessDefinition
    sequence do
      concurrent_iterator :on_value => "1, 2", :to_field => "f" do
        _print "${r:fei.expid} - ${f:f}"
      end
      _print "done."
    end
  end

  def test_1
    dotest(
      TestCase45a1,
      [ """
0.0.0.0 - 1
0.0.0.1 - 2
done.
        """.strip,
        """
0.0.0.1 - 2
0.0.0.0 - 1
done.
        """.strip
      ])
  end

  #
  # Test 2
  #

  class TestCase45a2 < OpenWFE::ProcessDefinition
    sequence do
      concurrent_iterator \
        :on_value => "1, 2",
        :to_field => "f",
        :over_if => "${f:__ip__} == 0" do

        _print "${r:fei.sub_instance_id} - ${f:f}"
      end
      _print "done."
    end
  end

  # test 'parked' for now

  def _test_2
    dotest(
      TestCase45a2,
      """
.0 - 1
.1 - 2
done.
      """.strip)
  end


  #
  # Test 3
  #

  class TestCase45a3 < OpenWFE::ProcessDefinition
    sequence do
      concurrent_iterator :on_value => "", :to_field => "f" do
        _print "${r:fei.sub_instance_id} - ${f:f}"
      end
      _print "done."
    end
  end

  def test_3
    dotest TestCase45a3, "done."
  end


  #
  # Test 4
  #

  class TestCase45a4 < OpenWFE::ProcessDefinition
    sequence do
      concurrent_iterator :on => "a, b, c", :to_field => "f" do
        _print "${f:f}"
      end
      set :var => "v", :value => "1, 2"
      concurrent_iterator :on_variable_value => "v", :to_field => "f" do
        _print "${f:f}"
      end
      concurrent_iterator :on_var_value => "v", :to_field => "f" do
        _print "${f:f}"
      end
      concurrent_iterator :on_var => "v", :to_field => "f" do
        _print "${f:f}"
      end
      _print "done."
    end
  end

  def test_4

    dotest(
      TestCase45a4,
      %w{ a b c 1 2 1 2 1 2 }.join("\n") + "\ndone.")
  end


  #
  # Test 5
  #

  class TestCase45a5 < OpenWFE::ProcessDefinition
    sequence do
      set :f => "f0", :value => "1, 2"
      concurrent_iterator :on_f => "f0", :to_field => "f" do
        _print "${f:f}"
      end
      concurrent_iterator :on_f => :f0, :to_field => "f" do
        _print "${f:f}"
      end
      _print "done."
    end
  end

  def test_5

    dotest(
      TestCase45a5,
      %w{ 1 2 1 2 }.join("\n") + "\ndone.")
  end


  #
  # Test 6
  #

  class Test6 < OpenWFE::ProcessDefinition
    concurrent_iterator :on => "a, b, c, d", :to_field => "f" do
      participant "${f:f}"
    end
  end

  def test_6

    @engine.register_participant ".", OpenWFE::NullParticipant

    fei = launch Test6

    sleep 0.350

    #puts @engine.get_expression_storage
    assert_equal 12, @engine.get_expression_storage.size

    @engine.cancel_process fei

    sleep 0.350

    assert_equal 1, @engine.get_expression_storage.size
  end

end

