#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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


#require 'rufus/treechecker'
  # is loaded only when needed

require 'fileutils'


module Ruote

  #
  # The TreeChecker service is used to check incoming external ruby code
  # and raise a security error if it contains potentially evil code.
  #
  class TreeChecker

    def initialize (context)

      (context['use_ruby_treechecker'] == false) and return

      require 'rufus/treechecker' # gem 'rufus-treechecker'
        # load only when needed

      @checker = Rufus::TreeChecker.new do

        exclude_fvccall :abort, :exit, :exit!
        exclude_fvccall :system, :fork, :syscall, :trap, :require, :load

        #exclude_call_to :class
        exclude_fvcall :private, :public, :protected

        #exclude_def               # no method definition
        exclude_eval              # no eval, module_eval or instance_eval
        exclude_backquotes        # no `rm -fR the/kitchen/sink`
        exclude_alias             # no alias or aliast_method
        exclude_global_vars       # $vars are off limits
        exclude_module_tinkering  # no module opening
        exclude_raise             # no raise or throw

        exclude_rebinding Kernel # no 'k = Kernel'

        exclude_access_to(
          IO, File, FileUtils, Process, Signal, Thread, ThreadGroup)

        #exclude_class_tinkering :except => Ruote::ProcessDefinition
          #
          # excludes defining/opening any class except
          # Ruote::ProcessDefinition

        exclude_call_to :instance_variable_get, :instance_variable_set
      end

      @cchecker = @checker.clone # and not dup
      @cchecker.add_rules do
        at_root do
          exclude_head [ :block ] # preventing 'a < b; do_sthing_evil()'
          exclude_head [ :lasgn ] # preventing 'a = 3'
        end
      end

      @checker.freeze
      @cchecker.freeze
      freeze
        #
        # preventing further modifications
    end

    def check (ruby_code)

      @checker.check(ruby_code) if @checker
    end

    def check_conditional (ruby_code)

      @cchecker.check(ruby_code) if @checker
    end
  end
end

