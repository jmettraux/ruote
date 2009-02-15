
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/rudefinitions'
require 'openwfe/expressions/rprocdef'
require 'openwfe/expressions/condition'


class ConditionalTest < Test::Unit::TestCase

  include OpenWFE::ConditionMixin
  include OpenWFE::OwfeServiceLocator


  def setup

    @debug = false

    @application_context = {}
    @application_context = {
      :s_tree_checker => OpenWFE::TreeChecker.new(nil, @application_context)
    }
  end

  #def teardown
  #end

  def test_0

    #@debug = true

    assert_t 'true'
    assert_F 'false'

    assert_t '1 == 1'

    assert_t "'a' == 'a'"
    assert_t '"a" == "a"'

    assert_t 'a == a'
    assert_F "'a' == a"

    #assert_t "!= ''"

    assert_F ' == 1 '
    assert_F ' == 1'
    assert_F '== 1'
  end

  def test_0b

    #@debug = true

    assert_t 'a'
    assert_F ''
  end

  def test_1

    #@debug = true

    assert_set_t '1 is set'
    assert_set_t '1 set'
    assert_set_F '1 is not set'
    assert_set_F '1 not set'

    assert_set_t ' is not set'
    assert_set_t ' not set'
    assert_set_F ' is set'
    assert_set_F ' set'

    assert_t '1 is set'
    assert_t '1 set'
    assert_F '1 is not set'
    assert_F '1 not set'

    assert_t ' is not set'
    assert_t ' not set'
    assert_F ' is set'
    assert_F ' set'
  end

  def test_2

    #@debug = true

    $my_owferu_var = nil

    #assert_F "f = File.open('toto', 'w'); f.puts('nada'); f.close"
    assert_t '$my_owferu_var = 3; $my_owferu_var = 4'

    target = on_jruby? ? 4 : nil
    assert_equal target, $my_owferu_var

    #assert_F "fe.reply('a')"
    #assert_t "fe.reply('a')"
  end

  protected

    #
    # just for test_2
    #
    def reply (m)

      @fei = nil
    end

    def assert_t (s, inv=false)

      r = eval_condition(s, nil)

      #puts "raw r is _#{r}_" if @debug

      r = (not r) if inv

      assert r, ">#{s}< should have evaluated to _#{not inv}_"
    end

    def assert_F (s)

      assert_t s, true
    end

    def assert_set_t (s, inv=false)

      r = eval_set s
      r = (not r) if inv

      assert r, ">#{s}< should have evaluated to _#{not inv}_"
    end

    def assert_set_F (s)

      assert_set_t s, true
    end

    #def evalc (s)
    #  eval_condition(s, nil)
    #end

    def lookup_attribute (attname, workitem)

      attname
    end

    def ldebug (&block)

      # don't do a thing
      return unless @debug

      puts '  ' + block.call
    end
end
