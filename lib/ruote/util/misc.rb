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

  # Will be set to true if the Ruby runtime is on Windows
  #
  WIN = (RUBY_PLATFORM.match(/mswin|mingw/) != nil)

  # Will be set to true if the Ruby runtime is JRuby
  #
  JAVA = (RUBY_PLATFORM.match(/java/) != nil)

  # Prints the current call stack to stdout
  #
  def self.p_caller (*msg)

    puts
    puts "  == #{msg.inspect} =="
    caller(1).each { |l| puts "  #{l}" }
    puts
  end

  # Deep object duplication
  #
  def self.fulldup (object)

    return object.fulldup if object.respond_to?(:fulldup)
      # trusting client objects providing a fulldup() implementation
      # Tomaso Tosolini 2007.12.11

    begin
      return Marshal.load(Marshal.dump(object))
        # as soon as possible try to use that Marshal technique
        # it's quite fast
    rescue TypeError => te
    end

    #if object.is_a?(REXML::Element)
    #  d = REXML::Document.new object.to_s
    #  return d if object.kind_of?(REXML::Document)
    #  return d.root
    #end
      # avoiding "TypeError: singleton can't be dumped"

    o = object.class.allocate

    # some kind of collection ?

    if object.is_a?(Array)
      object.each { |i| o << fulldup(i) }
    elsif object.is_a?(Hash)
      object.each { |k, v| o[fulldup(k)] = fulldup(v) }
    end

    # duplicate the attributes of the object

    object.instance_variables.each do |v|
      value = object.instance_variable_get(v)
      value = fulldup(value)
      begin
        o.instance_variable_set(v, value)
      rescue Exception => e
        # ignore, must be readonly
      end
    end

    o
  end

  # Returns true if the string seems to correpond to a URI
  #
  # TODO : wouldn't it be better to simply use URI.parse() ?
  #
  def self.is_uri? (s)

    s && (s.index('/') || s.match(/\.[^ ]+$/))
  end

  # Returns a neutralized version of s, suitable as a filename.
  #
  def self.neutralize (s)

    s.to_s.strip.gsub(/[ \/:;\*\\\+\?]/, '_')
  end

  # Tries to return an Integer or a Float from the given input. Returns
  #
  def self.narrow_to_number (o)

    return o if [ Fixnum, Bignum, Float ].include?(o.class)

    s = o.to_s

    (s.index('.') ? Float(s) : Integer(s)) rescue nil
  end

  # (simpler than the one from active_support)
  #
  def self.constantize (s)

    s.split('::').inject(Object) { |c, n| n == '' ? c : c.const_get(n) }
  end
end

