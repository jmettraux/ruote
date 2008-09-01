#
#--
# Copyright (c) 2008, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

require 'openwfe/service'

  require 'rufus/treechecker' #gem "rufus-treechecker"
    # only require if needed


module OpenWFE

  #
  # The TreeChecker service is used to check incoming external ruby code
  # and raise a security error if it contains potentially evil code.
  #
  class TreeChecker < Service

    #
    # builds the treechecker. Will return immediately (and not build)
    # if the :use_ruby_treechecker option is set to false. By default
    # the treechecker is used.
    #
    def initialize (service_name, application_context)

      super

      (ac[:use_ruby_treechecker] == false) and return

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

        exclude_class_tinkering OpenWFE::ProcessDefinition
          #
          # excludes defining/opening any class except
          # OpenWFE::ProcessDefinition

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

