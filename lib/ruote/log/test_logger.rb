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

#require 'ruote/util/tree'


module Ruote

  class TestLogger

    attr_reader :seen
    attr_reader :log

    attr_accessor :noisy

    def initialize (context)

      @context = context

      if @context.worker
        #
        # this is a worker context, DO log
        #
        @context.worker.subscribe(:all, self)
      #else
        #
        # this is not a worker context, DO NOT log, but be ready to
        # be queried
        #
      end

      @seen = []
      @log = []
      @waiting = nil

      @count = -1
      @color = 33
      @noisy = false

      # NOTE
      # in case of troubles, why not have the wait_for has an event ?
    end

    def notify (msg)

      #@context.storage.put(event.merge('type' => 'archived_msgs'))

      puts(pretty_print(msg)) if @noisy

      @seen << msg
      @log << msg

      check_waiting
    end

    def wait_for (interests)

      @waiting = [ Thread.current, interests ]

      check_waiting

      Thread.stop if @waiting

      # and when this thread gets woken up, go on and return __result__

      Thread.current['__result__']
    end

    # Debug only : dumps all the seen events to STDOUTS
    #
    def dump

      @seen.collect { |msg| pretty_print(msg) }.join("\n")
    end

    def color= (c)

      @color = c
    end

    def self.pp (msg)

      @logger ||= TestLogger.new(nil)
      puts @logger.send(:pretty_print, msg)
    end

    protected

    def check_waiting

      return unless @waiting

      while msg = @seen.shift

        break if check_msg(msg)
      end
    end

    def check_msg (msg)

      if check_interest(msg)

        thread = @waiting.first
        @waiting = nil
        thread['__result__'] = msg
        thread.wakeup

        true
      else

        false
      end
    end

    FINAL_ACTIONS = %w[ terminated ceased error_intercepted ]

    def check_interest (msg)

      action = msg['action']

      @waiting.last.each do |interest|

        satisfied =  if interest == :inactive

          (FINAL_ACTIONS.include?(action) && @context.worker.inactive?)

        elsif interest == :empty

          (action == 'terminated' && @context.storage.empty?('expressions'))

        elsif interest.is_a?(Symbol) # participant

          (action == 'dispatch' && msg['participant_name'] == interest.to_s)

        elsif interest.is_a?(Fixnum)

          @waiting[-1] = @waiting[-1] - [ interest ]
          if (interest > 1)
            @waiting[-1] << (interest - 1)
            false
          else
            true
          end

        else # wfid

          (FINAL_ACTIONS.include?(action) && msg['wfid'] == interest)
        end

        @waiting[-1] = @waiting[-1] - [ interest ] if satisfied
      end

      @waiting.last.size < 1
    end

    # <ESC>[{attr1};...;{attrn}m
    #
    # 0 Reset all attributes
    # 1 Bright
    # 2 Dim
    # 4 Underscore
    # 5 Blink
    # 7 Reverse
    # 8 Hidden
    #
    # Foreground Colours
    # 30 Black
    # 31 Red
    # 32 Green
    # 33 Yellow
    # 34 Blue
    # 35 Magenta
    # 36 Cyan
    # 37 White
    #
    # Background Colours
    # 40 Black
    # 41 Red
    # 42 Green
    # 43 Yellow
    # 44 Blue
    # 45 Magenta
    # 46 Cyan
    # 47 White

    def color (mod, s, clear=false)

      return s if Ruote::WIN
      return s unless STDOUT.tty?

      "[#{mod}m#{s}[0m#{clear ? '' : "[#{@color}m"}"
    end

    def pretty_print (msg)

      @count += 1
      @count = 0 if @count > 9

      ei = self.object_id.to_s[-2..-1]

      fei = msg['fei']
      depth = fei ? fei['expid'].split('_').size : 0

      i = fei ?
        [ fei['wfid'], fei['sub_wfid'], fei['expid'] ].join(' ') :
        msg['wfid']

      rest = msg.dup
      %w[
        _id put_at _rev
        type action
        fei wfid variables
      ].each { |k| rest.delete(k) }

      if v = rest['parent_id']
        rest['parent_id'] = Ruote.to_storage_id(v)
      end
      if v = rest.delete('workitem')
        rest[:wi] = [
          v['fei'] ? Ruote.to_storage_id(v['fei']) : nil,
          v['fields'].size ]
      end

      { 'tree' => :t, 'parent_id' => :pi }.each do |k0, k1|
        if v = rest.delete(k0)
          rest[k1] = v
        end
      end

      action = msg['action'][0, 2]
      action = case msg['action']
        when 'receive' then 'rc'
        when 'dispatched' then 'dd'
        when 'dispatch_cancel' then 'dc'
        else action
      end
      action = case action
        when 'la' then color('4;32', action)
        when 'te' then color('4;31', action)
        when 'ce' then color('31', action)
        when 'ca' then color('31', action)
        when 'rc' then color('4;33', action)
        when 'di' then color('4;33', action)
        when 'dd' then color('4;33', action)
        when 'dc' then color('4;31', action)
        else action
      end

      color(
        @color,
        "#{@count} #{ei} #{'  ' * depth}#{action} * #{i} #{rest.inspect}",
        true)
    end
  end
end

