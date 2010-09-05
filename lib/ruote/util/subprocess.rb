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


module Ruote

  #--
  # a few helper methods about subprocesses
  #++

  # This method is used by the 'subprocess' expression and by the
  # EngineParticipant.
  #
  def self.lookup_subprocess (fexp, ref)

    val = fexp.lookup_variable(ref)

    # a classical subprocess stored in a variable ?

    return [ '0', val ] if is_tree?(val)
    return val if is_pos_tree?(val)

    # maybe subprocess :ref => 'uri'

    subtree = fexp.context.parser.parse(ref) rescue nil

    _, subtree = Ruote::Exp::DefineExpression.reorganize(subtree) \
      if subtree && Ruote::Exp::DefineExpression.is_definition?(subtree)

    return [ '0', subtree ] if is_tree?(subtree)

    # no luck ...

    raise "no subprocess named '#{ref}' found"
  end

  def self.is_tree? (a)

    a.is_a?(Array) && a[1].is_a?(Hash) && a.size == 3
  end

  def self.is_pos_tree? (a)

    a.is_a?(Array) && a.size == 2 && a[0].is_a?(String) && is_tree?(a[1])
  end
end

