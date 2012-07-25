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
# Made in Germany.
# Author: Hartog de Mik
#++

module Ruote
  # an empty base class for observers, just to provide convenience and 
  # documentation on how observers operate
  #
  class ProcessObserver
    attr_reader :context, :options
    def initialize(context, options={})
      @context = context;
      @options = options
    end

    # Called when a process is launched
    #
    # Allows you to alter the initial fields and variables
    #
    # @param [Hash] options
    # @option options [Ruote::ProcessDefinition] pdef The Pdef launched (clone)
    # @option options [String] wfid The WFID of the process (clone)
    # @option options [Hash] fields The intial fields of the workitem
    # @option options [Hash] variables The process variables
    # @option options [Object] participant He who launched the process
    def on_launch(options)
    end

    # Called when a process is flunked
    # 
    # All the givens are clones, so any alterations will be lost
    # 
    # @param [Hash] options
    # @option options [Ruote::Workitem] workitem The workitem on flunk
    # @option options [Exception] error The raised exception
    # @option options [Object] participant He who flunked the process
    def on_flunk(options)
    end

    # Called when a participant replies
    #
    # @param [Hash] options
    # @option options [Ruote::Workitem] workitem The workitem that was replied
    # @option options [Object] participant He who replied
    def on_reply(options)
    end
  end
end