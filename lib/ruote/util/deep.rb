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
  # methods that go deep inside a nested structures of arrays and hashes
  # (JSON output maybe).
  #++

  # Given a hash and a key, deletes all the entries with that key, in child
  # hashes too.
  #
  # Note: this method is not related to the "dot notation" methods in this
  # lookup.rb file.
  #
  # == example
  #
  #   h = { 'a' => 1, 'b' => { 'a' => 2 } }
  #   Ruote.deep_delete(h, 'a')
  #     # => { 'b' => {} }
  #
  def self.deep_delete(h, key)

    h.delete(key)

    h.each { |k, v| deep_delete(v, key) if v.is_a?(Hash) }
  end

  class << self
    alias delete_all deep_delete
  end

  # Dives into a nested structure of hashes and arrays to find match hash keys.
  #
  # The method expects a block with 3 or 4 arguments.
  #
  # 3 arguments: collection, key and value
  # 4 arguments: parent collection, collection, key and value
  #
  # Warning: .deep_mutate forces hash keys to be strings. It's a JSON world.
  #
  # == example
  #
  #   h = {
  #     'a' => 0,
  #     'b' => 1,
  #     'c' => { 'a' => 2, 'b' => { 'a' => 3 } },
  #     'd' => [ { 'a' => 0 }, { 'b' => 4 } ] }
  #
  #   Ruote.deep_mutate(h, 'a') do |coll, k, v|
  #     coll['a'] = 10
  #   end
  #
  #   h # =>
  #     { 'a' => 10,
  #       'b' => 1,
  #       'c' => { 'a' => 10, 'b' => { 'a' => 10 } },
  #       'd' => [ { 'a' => 10 }, { 'b' => 4 } ] }
  #
  # == variations
  #
  # Instead of a single key, it's OK to pass an array of keys:
  #
  #   Ruote.deep_mutate(a, [ 'a', 'b' ]) do |coll, k, v|
  #     # ...
  #   end
  #
  # Regular expressions are made to match:
  #
  #   Ruote.deep_mutate(a, [ 'a', /^a\./ ]) do |coll, k, v|
  #     # ...
  #   end
  #
  # A single regular expression is OK:
  #
  #   Ruote.deep_mutate(a, /^user\./) do |coll, k, v|
  #     # ...
  #   end
  #
  def self.deep_mutate(coll, key_or_keys, parent=nil, &block)

    keys = key_or_keys.is_a?(Array) ? key_or_keys : [ key_or_keys ]

    if coll.is_a?(Hash)

      coll.dup.each do |k, v|

        # ensure that all keys are strings

        unless k.is_a?(String)

          coll.delete(k)
          k = k.to_s
          coll[k] = v
        end

        # call the mutation blocks for each match

        if keys.find { |kk| kk.is_a?(Regexp) ? kk.match(k) : kk == k }

          if block.arity > 3
            block.call(parent, coll, k, v)
          else
            block.call(coll, k, v)
          end
        end

        if v.is_a?(Array) || v.is_a?(Hash)

          deep_mutate(v, keys, coll, &block)
        end
      end

    elsif coll.is_a?(Array)

      coll.each { |e| deep_mutate(e, keys, coll, &block) }

    #else # nothing
    end
  end
end

