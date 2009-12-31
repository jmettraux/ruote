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


module Ruote

  #
  # The core methods for the Receiver class (sometimes a Mixin is easier
  # to integrate).
  #
  # (The engine itself includes this mixin)
  #
  module ReceiverMixin

    def receive (item)

      reply(item)
    end

    def reply (workitem)

      workitem = workitem.to_h if workitem.respond_to?(:to_h)

      @storage.put_msg(
        'receive',
        'fei' => workitem['fei'],
        'workitem' => workitem,
        'participant_name' => workitem['participant_name'],
        'receiver' => sign)
    end

    def sign

      self.class.to_s
    end
  end

  #
  # A receiver is meant to receive workitems and feed them back into the
  # engine (the storage actually).
  #
  class Receiver
    include ReceiverMixin

    def initialize (storage, options={})

      @storage = storage
      @options = options
    end
  end
end

