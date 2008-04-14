#
#--
# Copyright (c) 2005-2008, John Mettraux, OpenWFE.org
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.  
# 
# . Redistributions in binary form must reproduce the above copyright notice, 
#   this list of conditions and the following disclaimer in the documentation 
#   and/or other materials provided with the distribution.
# 
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "hecho en Costa Rica" and "made in Japan"
#
# john.mettraux@openwfe.org
#

require 'rexml/document'
require 'tmpdir'
require 'open-uri'


module OpenWFE

    #
    # see 
    # http://wiki.rubygarden.org/Ruby/page/show/Make_A_Deep_Copy_Of_An_Object
    #
    # It's not perfect (that's why fulldup() uses it only in certain cases).
    #
    # For example :
    #
    #     TypeError: singleton can't be dumped
    #         ./lib/openwfe/utils.rb:74:in `dump'
    #         ./lib/openwfe/utils.rb:74:in `deep_clone'
    #
    def OpenWFE.deep_clone (object)

        Marshal::load(Marshal.dump(object))
    end

    #
    # an automatic dup implementation attempt
    #
    def OpenWFE.fulldup (object)

        return nil if object == nil
    
        return object.fulldup if object.respond_to?("fulldup")
            # trusting client objects providing a fulldup() implementation
            # Tomaso Tosolini 2007.12.11

        return object if object.kind_of?(Float)
        return object if object.kind_of?(Fixnum)
        return object if object.kind_of?(TrueClass)
        return object if object.kind_of?(FalseClass)
        return object if object.kind_of?(Symbol)

        return object.dup if object.kind_of?(String)

        #return deep_clone(object) if object.kind_of?(REXML::Document)
        
        #return REXML::Document.new(object.to_s) \
        #    if object.kind_of? REXML::Document

        if object.kind_of?(REXML::Element)
            d = REXML::Document.new object.to_s
            return d if object.kind_of?(REXML::Document)
            return d.root
        end

        return deep_clone(object) if object.is_a?(Date)

        return Time.at(object) if object.is_a?(Time)
            # patch by Maarten Oelering 

        return Rational(object.denominator, object.numerator) \
            if object.kind_of?(Rational)

        o = nil

        begin
            o = object.class.new
        rescue ArgumentError => ae
            return deep_clone(object)
        end

        #
        # some kind of collection ?

        if object.kind_of?(Array)
            object.each do |i|
                o << fulldup(i)
            end
        elsif object.kind_of?(Hash)
            object.each do |k, v|
                o[fulldup(k)] = fulldup(v)
            end
        end

        #
        # duplicate the attributes of the object

        object.instance_variables.each do |v|

            #puts "v is #{v}"

            value = object.instance_variable_get(v)

            #puts "value is '#{value}'"

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

        string.gsub("-", "_")
    end

    def OpenWFE.to_dash (string)

        string.gsub("_", "-")
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

        s.gsub("\s", "_")
    end

    #
    # Returns an URI if the string is one, else returns nil.
    # No exception is thrown by this method.
    #
    def OpenWFE.parse_uri (string)

        return nil if string.split("\n").size > 1

        begin
            return URI::parse(string)
        rescue Exception => e
        end

        nil
    end

    #
    # Returns a URI instance if the given ref is a http, https, file or ftp
    # URI. Returns nil else.
    # The sister method parse_uri() is OK with things like mailto:, gopher:, ...
    #
    def OpenWFE.parse_known_uri (ref)

        uri = OpenWFE::parse_uri(ref.to_s)

        return nil unless uri

        return uri if uri.scheme == "file"
        return uri if uri.scheme == "http"
        return uri if uri.scheme == "https"
        return uri if uri.scheme == "ftp"
            # what else ...

        nil
    end

    #
    # Returns true if the given string starts with the 'start' string.
    #
    def OpenWFE.starts_with (string, start)
        #
        # my favourite way of doing that would be by adding this 
        # method to the String class, but that could be intrusive
        # (as OpenWFE is meant at first as an embeddable workflow engine).
        #
        return false unless string
        return false if string.length < start.length
        string[0, start.length] == start
    end

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
        s = "exception : "
        s << "#{exception}\n"
        s << exception.backtrace.join("\n")
        s
    end

    #
    # Pretty printing a caller() array
    #
    def OpenWFE.caller_to_s (start_index, max_lines=nil)
        s = ""
        caller(start_index + 1).each_with_index do |line, index|
            break if max_lines and index >= max_lines
            s << "   #{line}\n"
        end
        s
    end

    #
    # Sets the name of the current thread (the attribute :name if it is
    # a ruby thread, the java thread name if we're in JRuby)
    #
    def OpenWFE.set_current_thread_name (name)
       if defined?(JRUBY_VERSION)
           require 'java'
           java.lang.Thread.current_thread.name = "#{name} (Ruby Thread)"
       else
           Thread.current[:name] = name
       end
    end

    #
    # Some code for writing thinks like :
    #
    #     if async
    #         OpenWFE::call_in_thread "launch()", self do
    #             raw_expression.apply(wi)
    #         end
    #     else
    #         raw_expression.apply(wi)
    #     end
    #
    # Returns the new thread instance.
    #
    def OpenWFE.call_in_thread (caller_name, caller_object=nil, &block)

        return unless block

        Thread.new do

            #set_current_thread_name "call_in_thread() for '#{caller_name}'"
            set_current_thread_name caller_name

            begin
                #$SAFE = safe_level
                    #
                    # (note)
                    # doesn't work : the block inherits the safety level
                    # of its surroundings, it's a closure, ne ?

                block.call

            rescue Exception => e
                msg = "#{caller_name} caught an exception\n" + exception_to_s(e)
                if caller_object and caller_object.respond_to? :lwarn
                    caller_object.lwarn { msg }
                else
                    puts msg
                end
            end
        end
        # returns the thread
    end

    #
    # A small Timer class for debug purposes.
    #
    #     t = Time.new
    #
    #     # ... do something
    #
    #     puts "that something took #{t.duration} ms"
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


    #
    # (2008.03.12 Deprecated, kept here for a while
    # for backward compatibility)
    #
    # A simple Hash that accepts String or Symbol as lookup keys []
    #
    class SymbolHash < Hash
        def [] (key)
            super(key.to_s)
        end
    end

    #
    # Returns a version of s that is usable as or within a filename
    # (removes for examples things like '/' or '\'...)
    #
    def OpenWFE.ensure_for_filename (s)

        s = s.gsub(" ", "_")
        s = s.gsub("/", "_")
        s = s.gsub(":", "_")
        s = s.gsub(";", "_")
        s = s.gsub("\*", "_")
        s = s.gsub("\\", "_")
        s = s.gsub("\+", "_")
        s = s.gsub("\?", "_")

        s
    end

    #
    # "my//path" -> "my/path"
    #
    def OpenWFE.clean_path (s)
        s.gsub(/\/+/, "/")
    end

    #
    # This method is used within the InFlowWorkItem and the CsvTable classes.
    #
    def OpenWFE.lookup_attribute (container, key)

        key, rest = pop_key(key)

        #value = nil
        #begin
        #    value = container[key]
        #rescue Exception => e
        #end

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
    #     OpenWFE::grep "^..) ", "path/to/file.txt" do |line|
    #         puts " - '#{line.downcase}'"
    #     end
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
            open("http://www.openwfe.org")
            true
        rescue SocketError => se
            false
        end
    end

    protected

        def OpenWFE.pop_key (key)
            i = key.index(".")
            return narrow(key), nil unless i
            [ narrow(key[0..i-1]), key[i+1..-1] ]
        end

        def OpenWFE.pop_last_key (key)
            i = key.rindex(".")
            return nil, narrow(key) unless i
            [ key[0..i-1], narrow(key[i+1..-1]) ]
        end

        def OpenWFE.narrow (key)
            return 0 if key == "0"
            i = key.to_i
            return i if i != 0
            key
        end

        #
        # looks up in a container (something that has a [] method)  with a key,
        # if nothing has been found and the key is a number, turns the
        # the number into a String a does a last lookup.
        #
        def OpenWFE.flex_lookup (container, key)

            value = nil

            begin
                value = container[key]
            rescue Exception => e
            end

            if value == nil and key.kind_of?(Fixnum)
                begin
                    value = container[key.to_s]
                rescue Exception => e
                end
            end

            value
        end
    
end

