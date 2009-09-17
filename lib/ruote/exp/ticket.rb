#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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


module Ruote::Exp

  #
  # A mixin for expressions, adds methods about tickets to expressions.
  #
  module TicketMixin

    # When the TicketMixin gets included, it adds a with_ticket class method
    # that can be used to 'tag' methods that are to be wrapped with the
    # ticket mechanism.
    #
    def self.included (target_module)

      target_module.module_eval do

        def self.with_ticket (method_name)

          alias_method "without_ticket__#{method_name}", method_name

          class_eval(%{
            def #{method_name} (*args)
              with_ticket(:#{method_name}, *args)
            end
          })
        end
      end
    end

    protected

    # The actual ticketing mecha wrapper.
    #
    def with_ticket (method_name, *args)

      ticket = args.last.class.name.match(/Ticket$/) ? args.pop : nil
      ticket ||= expstorage.draw_ticket(self)

      if ticket.consumable?

        send("without_ticket__#{method_name}", *args)
        ticket.consume

      else

        sleep 0.014

        if exp = expstorage[@fei]

          args << ticket
          exp.with_ticket(method_name, *args)
        end
      end
    end

    # Discards all the tickets for this flow expression instance
    # (called when replying to the parent expression).
    #
    def discard_all_tickets

      expstorage.discard_all_tickets(@fei)
    end
  end
end

