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

    # Brute approach, grep until the process launch is reached...
    #
    def process_history (wfid)

      files = Dir[File.join(@path, "#{engine.engine_id}_*.txt")].reverse

      history = []

      files.each do |f|

        lines = File.readlines(f).reverse

        lines.each do |l|

          next unless l.match(/ #{wfid} /)

          history.unshift(l.strip)
          return history if l.match(/ processes launch$/)
        end
      end

      history # shouldn't occur, unless history [file] got lost
    end

    #def history_to_tree (wfid)
    #  # (NOTE why not ?)
    #end

    ABBREVIATIONS = {
      :processes => 'ps',
      :workitems => 'wi'
    }

    protected

    def ab (s)

      ABBREVIATIONS[s] || s.to_s
    end

    def receive (eclass, emsg, eargs)

      line = if eclass == :processes
        [ eargs[:wfid], ab(eclass), emsg ]
      elsif eclass == :workitems
        [ eargs[:workitem].fei.wfid, ab(eclass), emsg, eargs[:pname] ]
      else
        nil
      end

      return unless line

      rotate_if_necessary

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
end

