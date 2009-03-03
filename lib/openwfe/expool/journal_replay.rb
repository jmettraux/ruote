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


require 'openwfe/flowexpressionid'


module OpenWFE

  #
  # The code decicated to replay and reconstitute journal.
  #
  module JournalReplay

    #
    # Replays a given journal file.
    #
    # The offset can be determined by running the analyze() method.
    #
    # If 'trigger_action' is set to true, the apply or reply or cancel
    # action found at the given offset will be triggered.
    #
    def replay (file_path, offset, trigger_action=false)

      states = decompose(file_path)

      state = nil

      states.each do |s|
        state = s if s.offset == offset
      end

      raise "cannot replay offset #{offset}" unless state

      #puts "expstorage size 0 = #{get_expression_storage.size}"

      state.static.each do |update|
        flow_expression = update[3]
        flow_expression.application_context = @application_context
        get_expression_pool.update(flow_expression)
      end

      get_expression_pool.reschedule

      #puts "expstorage size 1 = #{get_expression_storage.size}"

      return unless trigger_action

      #puts "sds : #{state.dynamic.size}"

      state.dynamic.each do |ply|

        message = ply[0]
        #fei = extract_fei(ply[2])
        fei_or_fexp = ply[2]
        wi = ply[3]

        fei_or_fexp.application_context = @application_context \
          if fei_or_fexp.is_a?(FlowExpression)

        if wi
          #
          # apply, reply, reply_to_parent
          #
          #get_expression_pool.send message, fei, wi
          get_expression_pool.send message, fei_or_fexp, wi
        else
          #
          # cancel
          #
          get_expression_pool.send message, fei
        end
      end
    end

    #
    # Outputs a report of the each of the main events that the journal
    # traced.
    #
    # The output goes to the stdout.
    #
    # The output can be used to determine an offset number for a replay()
    # of the journal.
    #
    def analyze (file_path)

      states = decompose(file_path)

      states.each do |state|

        next if state.dynamic.length < 1

        puts
        puts state.to_s
        puts
      end
    end

    #
    # Decomposes the given file_path into a list of states
    #
    def decompose (file_path)

      do_decompose(load_events(file_path), [], nil, 0)
    end

    #
    # Loads a journal file and return the content as a list of
    # events. This method is made available for unit tests, as
    # a public method it has not much interest.
    #
    def load_events (file_path)

      File.open(file_path) do |f|
        s = YAML.load_stream f
        s.documents
      end
    end

    #
    # Takes an error event (as stored in the journal) and replays it
    # (usually you'd have to fix the engine conf before replaying
    # the error trigger)
    #
    # (Make sure to fix the cause of the error before triggering this
    # method)
    #
    def replay_at_error (error_source_event)

      get_workqueue.push(
        get_expression_pool,
        :do_apply_reply,
        error_source_event[3], # message (:apply for example)
        error_source_event[2], # fei or exp
        error_source_event[4]) # workitem

      # 0 is :error and 1 is the date and time of the error

      linfo do
        fei = extract_fei(error_source_event[2])
        "replay_at_error() #{error_source_event[3]} #{fei}"
      end
    end

    #
    # Detects the last error that ocurred for a workflow instance
    # and replays at that point (see replay_at_error).
    #
    # (Make sure to fix the cause of the error before triggering this
    # method)
    #
    def replay_at_last_error (wfid)

      events = load_events(get_path(wfid))

      error_event = events.reverse.find do |evt|
        evt[0] == :error
      end

      replay_at_error(error_event)
    end

    protected

      def do_decompose (events, result, previous_state, offset)

        current_state = extract_state(events, offset)

        return result unless current_state

        result << current_state

        do_decompose(events, result, current_state, offset + 1)
      end

      def extract_state (file, offset)

        events = if file.is_a?(String)
          load_events(file)
        else
          file
        end

        #
        # what to do with Sleep and When ?

        off = -1
        off = off - offset if offset

        return nil if (events.size + off < 0)

        events = events[0..off]

        date = events[-1][1]

        participants = {}

        seen = {}
        static = []
        events.reverse.each do |e|

          etype = e[0]
          fei = e[2]

          next if etype == :apply
          next if etype == :reply
          next if etype == :reply_to_parent
          next if etype == :error
          next if seen[fei]

          seen[fei] = true

          next if etype == :remove

          static << e

          participants[fei] = true \
            if e[3].is_a? OpenWFE::ParticipantExpression
        end

        seen = {}
        dynamic = []
        events.reverse.each do |e|
          etype = e[0]
          fei = extract_fei e[2]
          next if etype == :update
          next if etype == :remove
          next if etype == :error
          #next if etype == :reply_to_parent
          next if seen[fei]
          next unless participants[fei]
          seen[fei] = true
          dynamic << e
        end

        ExpoolState.new(offset, date, static, dynamic, participants)
      end

      class ExpoolState
        include FeiMixin

        attr_accessor \
          :offset,
          :date,
          :static,
          :dynamic,
          :participants

        def initialize (offset, date, static, dynamic, participants)

          @offset = offset
          @date = date
          @static = static
          @dynamic = dynamic
          @participants = participants
        end

        def to_s

          s = "=== offset : #{@offset}  #{@date} ===\n"

          s << "static :\n"
          @static.each do |e|
            s << " - #{e[0]}   #{extract_fei(e[2]).to_short_s}\n"
          end

          s << "\n"
          s << "dynamic :\n"
          @dynamic.each do |e|
            s << " - #{e[0]}   #{extract_fei(e[2]).to_short_s}\n"
          end

          s << "=== . ===\n\n"

          #s <<  "participants :\n"
          #@participants.each do |fei, v|
          #  s << " - #{fei.to_short_s}\n"
          #end

          s
        end
      end
  end
end
