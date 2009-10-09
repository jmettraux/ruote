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

require 'fileutils'
require 'ruote/engine/context'
require 'ruote/queue/subscriber'


module Ruote

  #
  # Logs the ruote engine history to files.
  #
  class FsHistory

    include EngineContext
    include Subscriber

    def context= (c)

      @context = c
      subscribe(:all)

      @path = @context[:history_path] || File.join(workdir, 'log')
      FileUtils.mkdir_p(@path)

      @last = nil
      @file = nil
      rotate_if_necessary
    end

    # Makes sure to close the history file.
    #
    def shutdown

      @file.close rescue nil
    end

    # Returns an array of Ruote::Record instances, each record represents
    # a ruote engine [history] event.
    # Returns an empty array if no history was found for the given wfid.
    #
    def process_history (wfid)

      files = Dir[File.join(@path, "#{engine.engine_id}_*.txt")].reverse

      history = []

      files.each do |f|

        lines = File.readlines(f).reverse

        lines.each do |l|

          next unless l.match(/ #{wfid} /)

          r = Record.split_line(engine.engine_id, l.strip)

          next unless r

          history.unshift(r)

          return history if r.is_process_launch?
        end
      end

      history # shouldn't occur, unless history [file] got lost
    end

    #def history_to_tree (wfid)
    #  # (NOTE why not ?)
    #end

    ABBREVIATIONS = {
      :processes => 'ps',
      :workitems => 'wi',
      :errors => 'er'
    }

    protected

    def ab (s)

      ABBREVIATIONS[s] || s.to_s
    end

    def fei (eargs)

      if i = eargs[:fei]
        return i
      end
      if wi = eargs[:workitem]
        return wi.fei
      end

      nil
    end

    def parent_wfid (eargs)

      if i = eargs[:wfid]
        return i
      end
      if i = fei(eargs)
        return i.parent_wfid
      end

      nil
    end

    def short_fei (eargs)

      if i = fei(eargs)
        i.sub_wfid ? "_#{i.sub_wfid} #{i.expid}" : i.expid
      else
        nil
      end
    end

    # This is the method called by the workqueue. Incoming engine events
    # are 'processed' here.
    #
    def receive (eclass, emsg, eargs)

      line = if eclass == :processes

        if emsg == :launch
          [ eargs[:tree][1].map { |k, v| "#{k}=#{v}" }.join(', ') ]
        #elsif emsg == :launch_sub
        #  [ short_fei(eargs), eargs.inspect ]
        else
          [ short_fei(eargs) ]
        end

      elsif eclass == :workitems

        [ short_fei(eargs), eargs[:pname] ]

      elsif eclass == :errors

        #p [ eclass, emsg, eargs ]
        return if emsg == :remove

        oeargs = eargs[:message].last
        error = eargs[:error]
        [ short_fei(oeargs), error.class, error.message ]

      else

        nil
      end

      return unless line

      rotate_if_necessary

      line.unshift(emsg)
      line.unshift(ab(eclass))
      line.unshift(parent_wfid(eargs))

      #line.unshift(@last.strftime('%F %T'))
      line.unshift("#{@last.strftime('%F %T')}.#{"%06d" % @last.usec}")

      @file.puts(line.join(' '))
      @file.flush
    end

    def rotate_if_necessary

      prev = @last
      @last = Time.now

      return if prev && prev.day == @last.day

      @file.close rescue nil

      fn = [
        Ruote.neutralize(engine.engine_id),
        'history',
        @last.strftime('%F')
      ].join('_') + '.txt'

      @file = File.open(File.join(@path, fn), 'a')
    end
  end

  # Represents a ruote engine [history] event.
  # Is returned by FsHistory.process_history(wfid) method calls.
  #
  class Record

    LINE_REGEX = /^([0-9-]{10} [^ ]+) ([^ ]+) ([a-z]{2}) (.+)$/
    MSG_REGEX = /^([^ ]+)( \_[0-9]+)?( [0-9\_]+)?(.*)$/

    attr_accessor :at, :wfid, :fei, :eclass, :event, :message, :engine_id

    # Returns a Record instance or nil (if the line can't be turned into
    # a Record).
    #
    def self.split_line (engine_id, l)

      m = LINE_REGEX.match(l)

      return nil unless m

      r = Record.new
      r.engine_id = engine_id
      r.at = Time.parse(m[1])
      r.wfid = m[2]
      r.eclass = m[3]
      r.send(:split_rest, m[4]) # that stays in the family

      r
    end

    def is_process_launch?

      (@eclass == 'ps' && @event == 'launch')
    end

    #attr_accessor :at, :wfid, :fei, :eclass, :event, :message, :engine_id

    def to_h

      %w[ at wfid fei eclass event message engine_id ].inject({}) { |h, a|

        v = self.send(a)
        h[a] = v.is_a?(FlowExpressionId) ? v.to_h : v.to_s

        h
      }
    end

    protected

    def rebuild_fei (wfid, sub_wfid, expid)

      fei = FlowExpressionId.new
      fei.wfid = sub_wfid ? "#{wfid}#{sub_wfid.strip}" : wfid
      fei.expid = expid.strip
      fei.engine_id = @engine_id
      fei
    end

    def split_rest (r)

      if m = MSG_REGEX.match(r)
        @event = m[1]
        @fei = m[3] ? rebuild_fei(wfid, m[2], m[3]) : nil
        @message = m[4].strip
      else
        @event = r
        @fei = nil
        @message = nil
      end
    end
  end
end

