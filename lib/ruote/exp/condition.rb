#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
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
  # A few helper methods for evaluating :if and :unless expression
  # attributes in process definitions.
  #
  module Condition

    REGEXES = {
      'evl_set' => /^(.+?)( +is)?( +not)?( +set)$/,
      'evl_null' => /^(.+?)( +is)?( +not)?( +null)$/,
      'evl_empty' => /^(.+[\]}"'])( +is)?( +not)?( +empty)$/
    }

    def self.apply? (sif, sunless)

      return (true?(sif)) if sif
      return ( ! true?(sunless)) if sunless

      true
    end

    # Returns true if the given conditional string evaluates to true.
    #
    def self.true? (conditional)

      conditional = unescape(conditional.to_s)

      REGEXES.each do |method, regex|
        if m = regex.match(conditional)
          return self.send(method, m)
        end
      end

      evl(conditional) ? true : false
    end

    # Evaluates the given [conditional] code string and returns the
    # result.
    #
    # Note : this is not a full Ruby evaluation !
    #
    def self.eval (code)

      evl(code)
    end

    protected

    def self.parse (conditional)

      Rufus::TreeChecker.parse(conditional)

    rescue NoMethodError => nme

      raise NoMethodError.new(
        "/!\\ please upgrade your rufus-treechecker gem /!\\"
      )

    rescue => e

      [ :false ]
    end

    def self.unescape (s)

      s.gsub('&amp;', '&').gsub('&gt;', '>').gsub('&lt;', '<')
    end

    COMPARATORS = %w[ == > < != >= <= ].collect { |c| c.to_sym }

    def self.evl (tree)

      return evl(parse(tree)) if tree.is_a?(String)

      return nil if tree == []

      return tree.last if tree.first == :str
      return tree.last if tree.first == :lit
      return nil if tree == [ :nil ]
      return true if tree == [ :true ]
      return false if tree == [ :false ]

      return ( ! evl(tree.last)) if tree.first == :not

      if tree[0] == :and
        return evl(tree[1]) && evl(tree[2])
      end
      if tree[0] == :or
        return evl(tree[1]) || evl(tree[2])
      end

      if tree[0] == :array
        return tree[1..-1].collect { |e| evl(e) }
      end
      if tree[0] == :hash
        return Hash.[](*tree[1..-1].collect { |e| evl(e) })
      end

      if tree[0] == :call && tree[2] == :=~
        return evl(tree[1]) =~ Regexp.new(evl(tree.last.last).to_s)
      end

      if tree[0] == :call && COMPARATORS.include?(tree[2])
        return evl(tree[1]).send(tree[2], evl(tree.last.last))
      end

      if tree[0] == :call && tree[1] == nil
        return tree[2].to_s
      end

      raise ArgumentError.new("cannot deal with : #{tree.inspect}")
    end

    def self.evl_set (match)

      set = evl(match[1])
      set = set != nil && set != ''
      set = false if match[1].match(/is$/) && match[2].nil?

      match[3].nil? ? set : ( ! set)
    end

    def self.evl_empty (match)

      object = evl(match[1])

      empty = if object.respond_to?(:empty?)
        object.empty?
      elsif object.nil?
        true
      else
        false
      end

      ( ! match[3].nil? ^ empty)
    end

    def self.evl_null (match)

      ( ! match[3].nil? ^ evl(match[1]).nil?)
    end
  end
end

