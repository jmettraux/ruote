#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


require 'rufus/treechecker'
require 'fileutils'


module Ruote

  #
  # The TreeChecker service is used to check incoming external ruby code
  # and raise a security error if it contains potentially evil code.
  #
  class TreeChecker

    def initialize(context)

      return if context['use_ruby_treechecker'] == false

      checker = Rufus::TreeChecker.new do

        exclude_fvccall :abort, :exit, :exit!
        exclude_fvccall :system, :fork, :syscall, :trap, :require, :load
        exclude_fvccall :at_exit

        #exclude_call_to :class
        exclude_fvcall :private, :public, :protected

        #exclude_raise             # no raise or throw

        exclude_eval              # no eval, module_eval or instance_eval
        exclude_backquotes        # no `rm -fR the/kitchen/sink`
        exclude_alias             # no alias or aliast_method
        exclude_global_vars       # $vars are off limits
        exclude_module_tinkering  # no module opening

        exclude_rebinding Kernel # no 'k = Kernel'

        exclude_access_to(
          IO, File, FileUtils, Process, Signal, Thread, ThreadGroup)

        #exclude_class_tinkering :except => Ruote::ProcessDefinition
          #
          # excludes defining/opening any class except
          # Ruote::ProcessDefinition

        exclude_call_to :instance_variable_get, :instance_variable_set
      end

      stricter_checker = checker.clone
      stricter_checker.add_rules do
        exclude_def    # no method definition
        exclude_raise  # no raise or throw
      end

      # the checker used when reading process definitions

      @def_checker = stricter_checker.clone # and not dup
      @def_checker.freeze

      ## the checker used when dealing with conditionals
      #
      #@con_checker = checker.clone # and not dup
      #@con_checker.add_rules do
      #  exclude_raise # no raise or throw
      #  at_root do
      #    exclude_head [ :block ] # preventing 'a < b; do_sthing_evil()'
      #    exclude_head [ :lasgn ] # preventing 'a = 3'
      #  end
      #end
      #@con_checker.freeze
        #
        # lib/ruote/exp/condition.rb doesn't use this treechecker
        # kept (commented out) for 'documentation'

      # the checker used when dealing with code in $(ruby:xxx}

      @dol_checker = stricter_checker.clone # and not dup
      @dol_checker.freeze

      # the checker used when dealing with BlockParticipant code

      @blo_checker = checker.clone # and not dup
      @blo_checker.add_rules do
        exclude_def    # no method definition
      end
      @blo_checker.freeze

      # the checker used for CodeParticipant

      @cod_checker = checker.clone # and not dup
      @cod_checker.freeze

      freeze
        # preventing further modifications
    end

    def definition_check(ruby_code)

      @def_checker.check(ruby_code) if @def_checker
    end

    def block_check(ruby_code)

      @blo_checker.check(ruby_code) if @blo_checker
    end

    def dollar_check(ruby_code)

      @dol_checker.check(ruby_code) if @dol_checker
    end

    def code_check(ruby_code)

      @cod_checker.check(ruby_code) if @cod_checker
    end
  end
end

