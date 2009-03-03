#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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


require 'irb'
require 'irb/completion'

#--
# borrowing ideas from
#
# http://groups.google.com/group/ruby-talk-google/browse_frm/thread/60ef4f8cff701e14/26ae883a7cc1da7f
#++


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

