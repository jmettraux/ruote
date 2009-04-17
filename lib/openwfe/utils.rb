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
# Made in Japan and Costa Rica.
#++


require 'openwfe/rexml'
require 'tmpdir'
require 'open-uri'


module OpenWFE

  #--
  # see
  # http://wiki.rubygarden.org/Ruby/page/show/Make_A_Deep_Copy_Of_An_Object
  #
  # It's not perfect (that's why fulldup() uses it only in certain cases).
  #
  # For example :
  #
  #   TypeError: singleton can't be dumped
  #     ./lib/openwfe/utils.rb:74:in `dump'
  #     ./lib/openwfe/utils.rb:74:in `deep_clone'
  #
  #def OpenWFE.deep_clone (object)
  #  Marshal.load(Marshal.dump(object))
  #end
  #++

  #--
  # classes that shouldn't get duplicated.
  #
  #IMMUTABLES = [ Symbol, Fixnum, TrueClass, FalseClass, Float ]
  #++

  #
  # an automatic dup implementation attempt
  #
  def OpenWFE.fulldup (object)

    return object.fulldup if object.respond_to?(:fulldup)
      # trusting client objects providing a fulldup() implementation
      # Tomaso Tosolini 2007.12.11

    begin
      return Marshal.load(Marshal.dump(object))
        # as soon as possible try to use that Marshal technique
        # it's quite fast
    rescue TypeError => te
    end

    if object.kind_of?(REXML::Element)
      d = REXML::Document.new object.to_s
      return d if object.kind_of?(REXML::Document)
      return d.root
    end
      # avoiding "TypeError: singleton can't be dumped"

    o = object.class.new

    #
    # some kind of collection ?
    if object.kind_of?(Array)
      object.each { |i| o << fulldup(i) }
    elsif object.kind_of?(Hash)
      object.each { |k, v| o[fulldup(k)] = fulldup(v) }
    end
    #
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

  def OpenWFE.to_underscore (string)

    string.gsub('-', '_')
  end

  def OpenWFE.to_dash (string)

    string.gsub('_', '-')
  end

  def OpenWFE.symbol_to_name (symbol)

    to_dash(symbol.to_s)
  end

  def OpenWFE.name_to_symbol (name)

    return name if name.is_a?(Symbol)
    to_underscore(name).intern
  end

  #
  # Turns all the spaces in string into underscores.
  # Returns the new String.
  #
  def OpenWFE.stu (s)

    s.gsub("\s", '_')
  end

  #
  # Returns an URI if the string is one, else returns nil.
  # No exception is thrown by this method.
  #
  def OpenWFE.parse_uri (string)

    return nil if string.index("\n")
      # cheap initial test

    URI.parse(string) rescue nil
  end

  #
  # Returns a URI instance if the given ref is a http, https, file or ftp
  # URI. Returns nil else.
  # The sister method parse_uri() is OK with things like mailto:, gopher:, ...
  #
  def OpenWFE.parse_known_uri (ref)

    uri = OpenWFE.parse_uri(ref.to_s)

    return nil unless uri

    return uri if uri.scheme == 'file'
    return uri if uri.scheme == 'http'
    return uri if uri.scheme == 'https'
    return uri if uri.scheme == 'ftp'
      # what else ...

    nil
  end

  #--
  # Returns true if the given string starts with the 'start' string.
  #
  #def OpenWFE.starts_with (string, start)
  #  #
  #  # my favourite way of doing that would be by adding this
  #  # method to the String class, but that could be intrusive
  #  # (as OpenWFE is meant at first as an embeddable workflow engine).
  #  #
  #  return false unless string
  #  return false if string.length < start.length
  #  string[0, start.length] == start
  #end
  #++

  #
  # Returns true if the given string ends with the '_end' string.
  #
  def OpenWFE.ends_with (string, _end)
    return false unless string
    return false if string.length < _end.length
    string[-_end.length..-1] == _end
  end

  #
  # Attempts at displaying a nice stack trace
  #
  def OpenWFE.exception_to_s (exception)
    "exception : #{exception}\n#{exception.backtrace.join("\n")}"
  end

  #
  # Pretty printing a caller() array
  #
  def OpenWFE.caller_to_s (start_index, max_lines=nil)
    s = ''
    caller(start_index + 1).each_with_index do |line, index|
      break if max_lines and index >= max_lines
      s << "   #{line}\n"
    end
    s
  end

  #--
  # Some code for writing thinks like :
  #
  #   if async
  #     OpenWFE::call_in_thread "launch()", self do
  #       raw_expression.apply(wi)
  #     end
  #   else
  #     raw_expression.apply(wi)
  #   end
  #
  # Returns the new thread instance.
  #
  #def OpenWFE.call_in_thread (caller_name, caller_object=nil, &block)
  #  return nil unless block
  #  t = Thread.new do
  #    begin
  #      #$SAFE = safe_level
  #        #
  #        # (note)
  #        # doesn't work : the block inherits the safety level
  #        # of its surroundings, it's a closure, ne ?
  #      block.call
  #    rescue Exception => e
  #      msg = "#{caller_name} caught an exception\n" + exception_to_s(e)
  #      if caller_object and caller_object.respond_to? :lwarn
  #        caller_object.lwarn { msg }
  #      else
  #        puts msg
  #      end
  #    end
  #  end
  #  t[:name] = caller_name
  #  t
  #end
  #++

  #
  # A small Timer class for debug purposes.
  #
  #   t = Time.new
  #
  #   # ... do something
  #
  #   puts "that something took #{t.duration} ms"
  #
  class Timer

    attr_reader :start

    def initialize
      @start = Time.now.to_f
    end

    #
    # Returns the number of milliseconds since this Timer was
    # instantiated.
    #
    def duration
      (Time.now.to_f - @start) * 1000
    end
  end

  #--
  # (2008.03.12 Deprecated, kept here for a while
  # for backward compatibility)
  #
  # A simple Hash that accepts String or Symbol as lookup keys []
  #
  #class SymbolHash < Hash
  #  def [] (key)
  #    super(key.to_s)
  #  end
  #end
  #++

  #
  # Returns a version of s that is usable as or within a filename
  # (removes for examples things like '/' or '\'...)
  #
  def OpenWFE.ensure_for_filename (s)

    s.gsub(/[ \/:;\*\\\+\?]/, '_')
  end

  #
  # "my//path" -> "my/path"
  #
  def OpenWFE.clean_path (s)

    s.gsub(/\/+/, '/')
  end

  #
  # This method is used within the InFlowWorkItem and the CsvTable classes.
  #
  def OpenWFE.lookup_attribute (container, key)

    key, rest = pop_key(key)

    value = flex_lookup(container, key)

    return value unless rest

    return nil unless value

    lookup_attribute(value, rest)
  end

  #
  # This method is used within the InFlowWorkItem and the CsvTable classes.
  #
  def OpenWFE.has_attribute? (container, key)

    key, last_key = pop_last_key(key)

    container = lookup_attribute(container, key) if key

    if container.respond_to?(:has_key?)

      (container.has_key?(last_key) or container.has_key?(last_key.to_s))

    elsif container.is_a?(Array) and last_key.is_a?(Fixnum)

      (last_key < container.length)

    else

      false
    end
  end

  #
  # Returns a list of lines matching the pattern in the given file.
  #
  # This is also possible :
  #
  #   OpenWFE::grep "^..) ", "path/to/file.txt" do |line|
  #     puts " - '#{line.downcase}'"
  #   end
  #
  # TODO : find a ruby library and use it instead of that code
  #
  def OpenWFE.grep (pattern, filepath, &block)

    result = []
    r = Regexp.new pattern

    File.open filepath do |file|
      file.readlines.each do |l|
        if r.match l
          if block
            block.call l
          else
            result << l
          end
        end
      end
    end
    result unless block
  end

  #
  # This method is used within the InFlowWorkItem and the CsvTable classes.
  #
  def OpenWFE.set_attribute (container, key, value)

    i = key.rindex(".")

    if not i
      container[key] = value
      return
    end

    container = lookup_attribute(container, key[0..i-1])
    container[key[i+1..-1]] = value
  end

  #
  # This method is used within the InFlowWorkItem and the CsvTable classes.
  #
  def OpenWFE.unset_attribute (container, key)

    i = key.rindex(".")

    if not i
      container.delete key
      return
    end

    container = lookup_attribute container, key[0..i-1]

    if container.is_a?(Array)

      container.delete_at key[i+1..-1].to_i
    else

      container.delete key[i+1..-1]
    end
  end

  #
  # Returns true if this host is currently online (has access to the web /
  # internet).
  #
  def online?

    require 'open-uri'

    begin
      open('http://www.openwfe.org')
      true
    rescue SocketError => se
      false
    end
  end

  protected

  def OpenWFE.pop_key (key)
    i = key.index('.')
    return narrow(key), nil unless i
    [ narrow(key[0..i-1]), key[i+1..-1] ]
  end

  def OpenWFE.pop_last_key (key)
    i = key.rindex('.')
    return nil, narrow(key) unless i
    [ key[0..i-1], narrow(key[i+1..-1]) ]
  end

  def OpenWFE.narrow (key)
    return 0 if key == '0'
    i = key.to_i
    return i if i != 0
    key
  end

  #
  # Looks up in a container (something that has a [] method)  with a key,
  # if nothing has been found and the key is a number, turns the
  # the number into a String a does a last lookup.
  #
  def OpenWFE.flex_lookup (container, key)

    value = (container[key] rescue nil)

    if value == nil and key.kind_of?(Fixnum)
      value = (container[key.to_s] rescue nil)
    end

    value
  end
end

