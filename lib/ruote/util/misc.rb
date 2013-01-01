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

require 'socket'


module Ruote

  # Will be set to true if the Ruby runtime is on Windows
  #
  WIN = (RUBY_PLATFORM.match(/mswin|mingw/) != nil)

  # Will be set to true if the Ruby runtime is JRuby
  #
  JAVA = (RUBY_PLATFORM.match(/java/) != nil)

  # Prints the current call stack to stdout
  #
  def self.p_caller(*msg)

    puts
    puts "  == #{msg.inspect} =="
    caller(1).each { |l| puts "  #{l}" }
    puts
  end

  # Deep object duplication
  #
  def self.fulldup(object)

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
      rescue
        # ignore, must be readonly
      end
    end

    o
  end

  # Returns true if the string seems to correpond to a URI
  #
  # TODO : wouldn't it be better to simply use URI.parse() ?
  #
  def self.is_uri?(s)

    s && (s.index('/') || s.match(/\.[^ ]+$/))
  end

  # Returns a neutralized version of s, suitable as a filename.
  #
  def self.neutralize(s)

    s.to_s.strip.gsub(/[ \/:;\*\\\+\?]/, '_')
  end

  # Tries to return an Integer or a Float from the given input. Returns
  #
  def self.narrow_to_number(o)

    return o if [ Fixnum, Bignum, Float ].include?(o.class)

    s = o.to_s

    (s.index('.') ? Float(s) : Integer(s)) rescue nil
  end

  # (simpler than the one from active_support)
  #
  def self.constantize(s)

    s.split('::').inject(Object) { |c, n| n == '' ? c : c.const_get(n) }
  end

  # Makes sure all they keys in the given hash are turned into strings
  # in the resulting hash.
  #
  def self.keys_to_s(h)

    h.remap { |(k, v), h| h[k.to_s] = v }
  end

  # Makes sure all they keys in the given hash are turned into symbols
  # in the resulting hash.
  #
  # Mostly used in ruote-amqp.
  #
  def self.keys_to_sym(h)

    h.remap { |(k, v), h| h[k.to_sym] = v }
  end

  REGEX_IN_STRING = /^\s*\/(.*)\/\s*$/

  #   regex_or_s("/nada/") #==> /nada/
  #   regex_or_s("nada") #==> "nada"
  #   regex_or_s(/nada/) #==> /nada/
  #
  def self.regex_or_s(s)

    if s.is_a?(String) && m = REGEX_IN_STRING.match(s)
      Regexp.new(m[1])
    else
      s
    end
  end

  # From http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
  #
  # Returns the (one of the) local IP address.
  #
  def self.local_ip

    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true
      # turn off reverse DNS resolution temporarily

    UDPSocket.open do |s|
      s.connect('64.233.187.99', 1)
      s.addr.last
    end

  rescue

    nil

  ensure
    Socket.do_not_reverse_lookup = orig
  end

  # Attempts to parse a string of Ruby code (and return the AST).
  #
  def self.parse_ruby(ruby_string)

    Rufus::TreeChecker.parse(ruby_string)

  rescue NoMethodError

    raise NoMethodError.new(
      "/!\\ please upgrade your rufus-treechecker gem /!\\")
  end

  # Returns an array. If the argument is an array, return it as is. Else
  # turns the argument into a string and "comma splits" it.
  #
  def self.comma_split(o)

    o.is_a?(Array) ? o : o.to_s.split(/\s*,\s*/).collect { |e| e.strip }
  end

  # A bit like #inspect but produces a tighter output (ambiguous to machines).
  #
  def self.insp(o, opts={})

    case o
      when nil
        'nil'
      when Hash
        trim = opts[:trim] || []
        '{' +
        o.reject { |k, v|
          v.nil? && trim.include?(k.to_s)
        }.collect { |k, v|
          "#{k}: #{insp(v)}"
        }.join(', ') +
        '}'
      when Array
        '[' + o.collect { |e| insp(e) }.join(', ') + ']'
      when String
        o.match(/\s/) ? o.inspect : o
      else
        o.inspect
    end
  end

  def self.pps(o, w=79)

    PP.pp(o, StringIO.new, w).string
  end

  #--
  # [de]camelize
  #++

  # Our own quick camelize implementation (no need to require active support).
  #
  def self.camelize(s, first_up=false)

    s = s.capitalize if first_up

    s.gsub(/(_.)/) { |x| x[1, 1].upcase }
  end

  # Quick decamelize implementation.
  #
  def self.decamelize(s)

    s.gsub(/(.)([A-Z])/, '\1_\2').downcase
  end
end

