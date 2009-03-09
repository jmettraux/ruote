#--
# Copyright (c) 2007-2009, Tomaso Tosolini, John Mettraux OpenWFE.org
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
# Made in Italy.
#++

require 'openwfe/expool/threaded_expstorage'
require 'openwfe/extras/expool/ar_expstorage'


module OpenWFE::Extras

  #
  # DEPRECATED !! use openwfe/extras/expool/ar_expstorage instead
  #
  # An extension of ArExpressionStorage that always stores its expression
  # as YAML (way slower than the default Marshal, but Marshal version
  # may differ over time).
  #
  # If you need to migrate from yaml to marshal and back (and other storage
  # variants), have a look at work/pooltool.ru
  #
  class DbExpressionStorage < ArExpressionStorage

    #
    # Constructor.
    #
    def initialize (service_name, application_context)

      application_context[:persist_as_yaml] = true

      super
    end
  end

  #
  # A DbExpressionStorage that does less work, for more performance,
  # thanks to the ThreadedStorageMixin.
  #
  # DEPRECATED. Use ArExpressionStorage.
  #
  class ThreadedDbExpressionStorage < DbExpressionStorage
    include OpenWFE::ThreadedStorageMixin

    def initialize (service_name, application_context)

      super

      start_queue
        #
        # which sets @thread_id
    end
  end
end

