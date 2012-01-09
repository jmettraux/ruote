#--
# Copyright (c) 2005-2012, John Mettraux, jmettraux@gmail.com
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
  # 're-opening' the FlowExpression class to add methods and classes about
  # on_error, on_cancel, on_timeout, ...
  #
  class FlowExpression

    # Looks up parent with on_error attribute and triggers it
    #
    def handle_on_error(msg, error)

      return false if h.state == 'failing'

      err = {
        'fei' => h.fei,
        'at' => Ruote.now_to_utc_s,
        'class' => error.class.to_s,
        'message' => error.message,
        'trace' => error.backtrace
      }

      oe_parent = lookup_on_error(err)

      return false unless oe_parent
        # no parent with on_error attribute found

      handler = oe_parent.local_on_error(err).to_s

      return false if handler == ''
        # empty on_error handler nullifies ancestor's on_error

      workitem = msg['workitem']
      workitem['fields']['__error__'] = err

      @context.storage.put_msg(
        'fail',
        'fei' => oe_parent.h.fei,
        'workitem' => workitem)

      true # yes, error is being handled.
    end

    protected

    #
    # Used by on_error when patterns are involved. Gathers much of the
    # pattern logic...
    #
    class HandlerEntry

      attr_reader :pattern, :action, :child_id

      def initialize(on_error_entry)

        if on_error_entry.is_a?(Hash)
          on_error_entry = on_error_entry.to_a.flatten
        end

        @pattern, @action, @child_id = on_error_entry
        @pat = Ruote.regex_or_s(@pattern) || //
      end

      def split(pat)

        @action.split(pat)
      end

      def match(regex_or_err)

        if regex_or_err.is_a?(Regexp)
          @action.match(regex_or_err)
        else
          @pat.match(regex_or_err['message']) ||
          @pat.match(regex_or_err['class'])
        end
      end

      def narrow

        @action.is_a?(Array) ? @action : self
      end

      def update_tree(tree, retries)

        child = tree[2][@child_id]

        if @pattern
          if retries.empty?
            child[1].delete(@pattern)
          else
            child[1][@pattern] = retries.join(', ')
          end
        else
          key, _ = child[1].find { |k, v| v.nil? }
          child[1].delete(key)
          child[1][retries.join(', ')] = nil if retries.any?
        end
      end
    end

    # Given an error, returns the on_error registered for it, or nil if none.
    #
    def local_on_error(err)

      if h.on_error.is_a?(String) or Ruote.is_tree?(h.on_error)

        return h.on_error
      end

      if h.on_error.is_a?(Array)

        # all for the 'on_error' expression
        # see test/functional/eft_38_

        h.on_error.each do |oe|

          if (he = HandlerEntry.new(oe)).match(err)
            return he.narrow
          end
        end
      end

      nil
    end

    # Looks up "on_error" attribute locally and in the parent expressions,
    # if any.
    #
    def lookup_on_error(err)

      if local_on_error(err)
        return self
      end
      if par = parent
        return par.lookup_on_error(err)
      end

      nil
    end

    # (Called by #trigger & co)
    #
    def supplant_with(tree, opts)

      # at first, nuke self

      r = try_unpersist

      raise(
        "failed to remove exp to supplant "+
        "#{Ruote.to_storage_id(h.fei)} #{tree.first}"
      ) if r.respond_to?(:keys)

      # then re-apply

      if t = opts['trigger']
        tree[1]['_triggered'] = t.to_s
      end

      @context.storage.put_msg(
        'apply',
        { 'fei' => h.fei,
          'parent_id' => h.parent_id,
          'tree' => tree,
          'workitem' => h.applied_workitem,
          'variables' => h.variables
        }.merge!(opts))
    end

    # Called by #trigger when it encounters something like
    #
    #   :on_error => '5m: retry, pass'
    #
    def schedule_retries(handler, err)

      retries = handler.split(/\s*,\s*/)
      after, action = retries.shift.split(/:/)

      # deal with "* 3"

      if m = action.match(/^ *([^ ]+) *\* *(\d+)$/)

        count = m[2].to_i - 1

        if count == 1
          retries.unshift("#{after}: #{m[1]}")
        elsif count > 1
          retries.unshift("#{after}: #{m[1]} * #{count}")
        end
      end

      # rewrite tree to remove current retry

      t = Ruote.fulldup(tree)

      if h.on_error.is_a?(Array)
        handler.update_tree(t, retries)
      else
        if retries.empty?
          t[1].delete('on_error')
        else
          t[1]['on_error'] = retries.join(', ')
        end
      end

      update_tree(t)

      # schedule current retry

      after = after.strip
      action = action.strip

      msg = {
        'action' => 'cancel',
        'fei' => h.fei,
        'flavour' => 'retry',
        're_apply' => true }

      (h.timers ||= []) <<
        [ @context.storage.put_schedule('at', h.fei, after, msg), 'retry' ]

      # over

      persist_or_raise

    rescue Exception => e

      raise Ruote::MetaError.new(__method__.to_s, e)
    end

    # 'on_{error|timeout|cancel|re_apply}' triggering
    #
    def trigger(on, workitem)

      err = h.applied_workitem['fields']['__error__']

      handler = on == 'on_error' ? local_on_error(err) : h[on]

      if on == 'on_error' && handler.respond_to?(:match) && handler.match(/:/)

        return schedule_retries(handler, err)
      end

      new_tree = case handler
        when Array then handler
        when HandlerEntry then [ handler.action, {}, [] ]
        else [ handler.to_s, {}, [] ]
      end

      if on == 'on_error' || on == 'on_timeout'

        handler = handler.action if handler.is_a?(HandlerEntry)

        case handler

          when 'redo', 'retry'

            new_tree = tree

          when 'undo', 'pass'

            h.state = 'failed'
            reply_to_parent(workitem)

            return # let's forget this error

          when CommandExpression::REGEXP

            hh = handler.split(' ')
            command = hh.first
            step = hh.last
              # 'jump to shark' or 'jump shark', ...

            h.state = nil
            workitem['fields'][CommandMixin::F_COMMAND] = [ command, step ]

            reply(workitem)

            return # we're dealing with it
        end
      end

      supplant_with(new_tree, 'trigger' => on)
    end
  end
end

