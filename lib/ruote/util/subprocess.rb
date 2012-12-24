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


module Ruote

  #--
  # a few helper methods about subprocesses
  #++

  # This method is used by the 'subprocess' expression and by the
  # EngineParticipant.
  #
  def self.lookup_subprocess(fexp, ref)

    val = fexp.lookup_variable(ref)

    # a classical subprocess stored in a variable ?

    return [ '0', val ] if is_tree?(val)
    return val if is_pos_tree?(val)

    # maybe subprocess :ref => 'uri'

    subtree = fexp.context.reader.read(ref) rescue nil

    if subtree && is_definition_tree?(subtree)
      _, subtree = Ruote::Exp::DefineExpression.reorganize(subtree)
    end

    return [ '0', subtree ] if is_tree?(subtree)

    # no luck ...

    raise "no subprocess named '#{ref}' found"
  end

  # Returns true if the argument is a process definition tree (whose root
  # is 'define', 'process_definition' or 'workflow_definition'.
  #
  def self.is_definition_tree?(arg)

    Ruote::Exp::DefineExpression.is_definition?(arg) && is_tree?(arg)
  end

  # Returns true if the given argument is a process definition tree
  # (its root doesn't need to be 'define' or 'process_definition' though).
  #
  def self.is_tree?(arg)

    arg.is_a?(Array) && arg.size == 3 &&
    arg[0].is_a?(String) && arg[1].is_a?(Hash) && arg[2].is_a?(Array) &&
    (arg.last.empty? || arg.last.find { |e| ! is_tree?(e) }.nil?)
  end

  # Mainly used by Ruote.lookup_subprocess, returns true if the argument is
  # is an array [ position, tree ].
  #
  def self.is_pos_tree?(arg)

    arg.is_a?(Array) &&
    arg.size == 2 &&
    arg[0].is_a?(String) &&
    is_tree?(arg[1])
  end
end

