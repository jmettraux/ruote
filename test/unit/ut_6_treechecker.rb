
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon May 12 14:12:54 JST 2008
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/util/treechecker'
require 'openwfe/expressions/rprocdef'


class TreeCheckerTest < Test::Unit::TestCase

  def test_0

    assert_safe :check, '1+1'
    assert_unsafe :check, 'exit'
    assert_unsafe :check, 'puts $BATEAU'
    assert_unsafe :check, 'def surf }'
    assert_unsafe :check, 'abort'
    assert_unsafe :check, "abort; puts 'ok'"
    assert_unsafe :check, "puts 'ok'; abort"

    assert_unsafe :check, 'exit 0'
    assert_unsafe :check, "system('whatever')"

    assert_unsafe :check, 'alias :a :b'
    assert_unsafe :check, 'alias_method :a :b'

    assert_unsafe :check, "File.open('x')"
    assert_unsafe :check, "FileUtils.rm('x')"

    assert_unsafe :check, "eval 'nada'"
    assert_unsafe :check, "M.module_eval 'nada'"
    assert_unsafe :check, "o.instance_eval 'nada'"
  end

  def test_1

    assert_safe :check_conditional, '1 == 1'
    assert_unsafe :check_conditional, "puts 'ok'; 1 == 1"
    assert_unsafe :check_conditional, 'exit'

    assert_unsafe :check_conditional, 'a = 2'
  end

  def test_2

    assert_safe :check, "class Toto < OpenWFE::ProcessDefinition\nend"
    assert_unsafe :check, "class String\nend"
    assert_unsafe :check, "module Whatever\nend"
    assert_unsafe :check, "class << e\nend"
  end

  def test_3

    assert_unsafe :check, 'trap'
    assert_unsafe :check, 'Kernel.trap'
    assert_unsafe :check, 'k = Kernel; k.trap'
    assert_unsafe :check, 'k = Kernel; k.trap(x)'
    assert_unsafe :check, 'k = ::Kernel; k.trap(x)'
  end

  protected

  def assert_safe (check_method, code)

    assert check(check_method, code)
  end

  def assert_unsafe (check_method, code)

    assert (not check(check_method, code))
  end

  def check (check_method, code)

    begin

      tc = OpenWFE::TreeChecker.new(nil, {})
      #tc.instance_variable_get(:@checker).ptree code
      #puts "\n==="
      #puts tc.instance_variable_get(:@checker)
      #puts "==="
      #puts tc.instance_variable_get(:@cchecker)
      tc.send check_method, code

    rescue Exception => e
      #puts "caught..."
      #puts ":: #{e}"
      #puts e.backtrace
      return false
    end

    true
  end
end
