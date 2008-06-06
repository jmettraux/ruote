#
#--
# Copyright (c) 2007, John Mettraux, OpenWFE.org
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
# $Id$
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

require 'irb'
require 'irb/completion'

#
# borrowing ideas from
#
# http://groups.google.com/group/ruby-talk-google/browse_frm/thread/60ef4f8cff701e14/26ae883a7cc1da7f


module OpenWFE

  #
  # Binds the SIGINT signal so that a console is opened with the bindings
  # specified in 'args'.
  #
  def OpenWFE.trap_int_irb (*args)
    trap 'INT' do
      OpenWFE.start_irb_session(*args)
      #OpenWFE.trap_int_irb(*args) if $openwfe_irb
      OpenWFE.trap_int_irb(*args)
    end
  end

  protected

    def OpenWFE.start_irb_session (*args)

      IRB::setup nil unless $openwfe_irb

      ws = IRB::WorkSpace.new *args

      $openwfe_irb = IRB::Irb.new ws

      IRB::conf[:MAIN_CONTEXT] = $openwfe_irb.context

      trap 'INT' do
        $openwfe_irb.signal_handle
      end

      $openwfe_irb.eval_input

      puts "\nbye!"
    end
end

