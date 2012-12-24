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


module Ruote::Exp

  #
  # The methods about the :filter attribute are placed in FlowExpression
  # from here.
  #
  class FlowExpression

    protected

    # The :filter attribute work is done here, at apply (in) and at reply (out).
    #
    def filter(workitem=nil)

      filter = lookup_filter(workitem)

      return unless filter

      unless filter.is_a?(Array)
        #
        # filter is a participant

        def filter.receive(wi); end
          # making sure the participant never replies to the engine

        hwi = workitem || h.applied_workitem

        if filter.respond_to?(:filter)
          hwi['fields'] = filter.filter(hwi['fields'], workitem ? 'out' : 'in')
        else
          hwi['fields']['__filter_direction__'] = workitem ? 'out' : 'in'
          filter.consume(Ruote::Workitem.new(hwi))
        end

        hwi['fields'].delete('__filter_direction__')

        return
      end

      #
      # filter is a not a participnat

      unless workitem # in

        h.fields_pre_filter =
          Rufus::Json.dup(h.applied_workitem['fields'])
        h.applied_workitem['fields'] =
          Ruote.filter(filter, h.applied_workitem['fields'], {})

      else # out

        workitem['fields'] =
          Ruote.filter(
            filter,
            workitem['fields'],
            :double_tilde =>
              h.fields_pre_filter || h.applied_workitem['fields'])

        workitem['fields'].delete('params')
          # take and discard tend to copy it over, so let's remove it
      end
    end

    # Used by #filter, deals with the various ways to pass filters
    # (directly, via a variable, via a participant, in and out, ...)
    #
    # Returns nil, if there is no filter. Raises an ArgumentError if the
    # filter is not usable. Returns the instantiated participant if the
    # filter points to a participant filter.
    #
    def lookup_filter(workitem)

      f = attribute(:filter)

      if f.nil? and workitem

        reply = if t = attribute(:take)
          Array(t).collect { |tt| { 'field' => tt, 'take' => true } }
        elsif d = attribute(:discard)
          if d == true
            [ { 'field' => /.+/, 'discard' => 'all' } ]
          else
            Array(d).collect { |dd| { 'field' => dd, 'discard' => true } }
          end
        else
          nil
        end

        f = { 'reply' => reply } if reply
      end

      return nil unless f
        # no filter

      if f.is_a?(Hash)
        f['in'] = [] unless f['in'] or f['apply']
        f['out'] = [] unless f['out'] or f['reply']
      end
        # empty ins and outs for a sucessful narrowing

      3.times { f = narrow_filter(f, workitem) }

      f or raise ArgumentError.new("found no filter corresponding to '#{f}'")
    end

    # Called successively to dig for the filter (Array or Participant).
    #
    def narrow_filter(fi, workitem)

      if fi.is_a?(Array) or fi.respond_to?(:consume) or fi.respond_to?(:filter)

        fi

      elsif fi.is_a?(Hash)

        workitem ? fi['out'] || fi['reply'] : fi['in'] || fi['apply']

      elsif fi.is_a?(String)

        filter =
          lookup_variable(fi) ||
          @context.plist.lookup(fi, workitem || h.applied_workitem)

        if filter.respond_to?(:consume) or filter.respond_to?(:filter)
          (workitem || h.applied_workitem)['participant_name'] = fi
        end

        filter

      else

        nil
      end
    end
  end
end

