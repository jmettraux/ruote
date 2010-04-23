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

  #   h = { 'a' => { 'b' => [ 1, 3, 4 ] } }
  #
  #   p Ruote.lookup(h, 'a.b.1') # => 3
  #
  def Ruote.lookup (collection, key, container_lookup=false)

    key, rest = pop_key(key)
    value = flookup(collection, key)

    return [ key, collection ] if container_lookup && rest.size == 0
    return [ rest.first, value ] if container_lookup && rest.size == 1
    return value if rest.size == 0
    return nil if value == nil

    lookup(value, rest)
  end

  #   h = { 'customer' => { 'name' => 'alpha' } }
  #
  #   Ruote.set(h, 'customer.name', 'bravo')
  #
  #   h #=> { 'customer' => { 'name' => 'bravo' } }
  #
  def Ruote.set (collection, key, value)

    k, c = lookup(collection, key, true)

    if c
      k = k.to_i if c.is_a?(Array)
      c[k] = value
    else
      collection[key] = value
    end
  end

  #   h = { 'customer' => { 'name' => 'alpha', 'rank' => '1st' } }
  #   r = Ruote.unset(h, 'customer.rank')
  #
  #   h # => { 'customer' => { 'name' => 'alpha' } }
  #   r # => '1st'
  #
  def Ruote.unset (collection, key)

    k, c = lookup(collection, key, true)

    return collection.delete(key) unless c

    if c.is_a?(Array)
      c.delete_at(Integer(k)) rescue nil
    else
      c.delete(k)
    end
  end

  protected # well...

  def Ruote.pop_key (key)

    ks = key.is_a?(String) ? key.split('.') : key

    [ narrow_key(ks.first), ks[1..-1] ]
  end

  def Ruote.narrow_key (key)

    return 0 if key == '0'

    i = key.to_i
    return i if i != 0

    key
  end

  def Ruote.flookup (collection, key)

    value = (collection[key] rescue nil)

    if value == nil and key.is_a?(Fixnum)
      value = (collection[key.to_s] rescue nil)
    end

    value
  end
end

