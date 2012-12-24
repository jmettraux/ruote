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
  # 're-opening' the FlowExpression class to add methods and classes about
  # on_error, on_cancel, on_timeout, ...
  #
  class FlowExpression

    # Given this expression and an error, deflates the error into a hash
    # (serializable).
    #
    def deflate(err)

      {
        'fei' => h.fei,
        'at' => Ruote.now_to_utc_s,
        'class' => err.class.to_s,
        'message' => err.message,
        'trace' => err.backtrace,
        'details' => err.respond_to?(:ruote_details) ? err.ruote_details : nil,
        'deviations' => err.respond_to?(:deviations) ? err.deviations : nil,
        'tree' => tree
      }
    end

    # Returns a dummy expression. Only used by the error_handler service.
    #
    def self.dummy(h)

      class << h; include Ruote::HashDot; end

      fe = self.allocate
      fe.instance_variable_set(:@h, h)

      fe
    end

    # Looks up parent with on_error attribute and triggers it
    #
    def handle_on_error(msg, error)

      return false if h.state == 'failing'

      err = deflate(error)
      oe_parent = lookup_on_error(err)

      return false unless oe_parent
        # no parent with on_error attribute found

      handler = oe_parent.local_on_error(err)

      return false if handler.to_s == ''
        # empty on_error handler nullifies ancestor's on_error

      workitem = msg['workitem']
      workitem['fields']['__error__'] = err

      immediate = if handler.is_a?(String)
        !! handler.match(/^!/)
      elsif handler.is_a?(Array)
        !! handler.first.to_s.match(/^!/)
      else
        false
      end

      # NOTE: why not pass the handler in the msg?
      #       no, because of HandlerEntry (not JSON serializable)

      @context.storage.put_msg(
        'fail',
        'fei' => oe_parent.h.fei,
        'workitem' => workitem,
        'immediate' => immediate)

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

    # Called by #trigger when it encounters something like
    #
    #   :on_error => '5m: retry, pass'
    #
    def schedule_retries(handler, err)

      retries = handler.split(/\s*,\s*/)

      after, action = retries.shift.split(/:/)
      (after, action = '0', after) if action.nil?

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

    rescue => e

      raise Ruote::MetaError.new(__method__.to_s, e)
    end

    # 'on_{error|timeout|cancel|re_apply}' triggering
    #
    def trigger(on, workitem)

      tree = tree()
      err = h.applied_workitem['fields']['__error__']

      handler = on == 'on_error' ? local_on_error(err) : h[on]

      if on == 'on_error' && handler.to_s.match(/^!(.+)$/)
        handler = $1
      end

      if handler.is_a?(Hash) # on_re_apply

        wi = handler['workitem']
        fi = handler['fields']
        me = handler['merge_in_fields']

        workitem = if wi == 'applied' || me
          h.applied_workitem
        elsif wi
          wi
        else
          workitem
        end

        workitem['fields'] = fi if fi
        workitem['fields'].merge!(me) if me
      end

      if h.trigger && t = workitem['fields']["__#{h.trigger}__"]
        #
        # the "second take"...

        handler = t
        tree = h.supplanted['original_tree']
        workitem = h.supplanted['applied_workitem']
      end

      if on == 'on_error' && handler.respond_to?(:match) && handler.match(/[,:\*]/)
        return schedule_retries(handler, err)
      end

      new_tree = case handler
        when Hash then handler['tree']
        when Array then handler
        when HandlerEntry then [ handler.action, {}, [] ]
        else [ handler.to_s, {}, [] ]
      end

      handler = handler.action if handler.is_a?(HandlerEntry)
      handler = handler.strip if handler.respond_to?(:strip)

      if handler =~ /^can(cel|do)$/ && (on == 'on_cancel' || h.on_cancel == nil)
        handler = handler == 'cancel' ? 'undo' : 'redo'
      end

      h.on_reply = nil if on == 'on_reply'
        # preventing cascades

      case handler

        when 'redo', 'retry'
          #
          # retry with the same tree as before

          new_tree = tree

        when 'undo', 'pass', ''
          #
          # let's forget it

          h.state = on == 'on_cancel' ? 'cancelled' : 'failed'

          reply_to_parent(workitem); return

        when 'cancel'
          #
          # let's trigger on the on_cancel

          trigger('on_cancel', workitem); return

        when 'cando'
          #
          # trigger on_cancel, then redo

          h.on_reply = tree

          trigger('on_cancel', workitem); return

        when 'raise'
          #
          # re-raise

          raise Ruote.constantize(err['class']), err['message'], err['trace']

        when CommandExpression::REGEXP
          #
          # a command like 'jump to shark'...

          hh = handler.split(' ')
          command = hh.first
          step = hh.last

          h.state = nil
          workitem['fields'][CommandMixin::F_COMMAND] = [ command, step ]

          reply(workitem); return

        #else
        #
        #  if h.trigger
        #    #
        #    # do not accept participant or subprocess names
        #    # for "second trigger"
        #
        #    h.state = 'failed'
        #    reply_to_parent(workitem)
        #    return
        #  end
          #
          # actually, let's not care about that, let's trust people.
      end

      workitem = h.applied_workitem if on == 'on_error'

      #
      # supplant this expression with new tree

      r = try_unpersist

      raise(
        "failed to remove exp to supplant " +
        "#{Ruote.to_storage_id(h.fei)} #{tree.first}"
      ) if r.respond_to?(:keys)

      if new_tree[0].match(/^!(.+)$/); new_tree[0] = $1; end
      new_tree[1]['_triggered'] = on

      attributes.each { |k, v|
        new_tree[1][k] = v if (k.match(/^on_/) && k != on) || k == 'tag'
      }
        #
        # let the triggered tree have the same on_ attributes as the original
        # expression, so that on_cancel/on_error/on_x effects still apply
        #
        # 'tag' is copied as well. (so that 'left_tag' is emitted too)
        #
        # Should 'timeout', should other common attributes be copied as well?

      @context.storage.put_msg(
        'apply',
        { 'fei' => h.fei,
          'parent_id' => h.parent_id,
          'tree' => new_tree,
          'workitem' => workitem,
          'variables' => h.variables,
          'trigger' => on,
          'on_reply' => h.on_reply,
          'supplanted' => {
            'tree' => tree,
            'original_tree' => original_tree,
            'applied_workitem' => h.applied_workitem,
            'variables' => h.variables
          }})
    end
  end
end

