#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
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
# Made in Japan (as opposed to "swiss made").
#++


module OpenWFE

  #
  # A utility module to assist with JSON encoding/decoding using
  # pluggable JSON backends provided by #OpenWFE::Json::Backend.
  #
  module Json

    # See #decode
    def self.from_json (text)

      # DEPRECATED : Use decode()

      self.decode( text )
    end

    #
    # Makes sure the input is turned into a hash
    #
    def self.as_h (h_or_json)

      h_or_json.is_a?(Hash) ? h_or_json : decode(h_or_json)
    end

    # JSON encode the provided object using a pluggable JSON backend
    def self.encode( obj )
      Backend.proxy.encode( obj )
    end

    # Decode the provided JSON string using a pluggable JSON backend
    def self.decode( json )
      Backend.proxy.decode( json )
    end

    #
    # Support for dynamically adjustable JSON backends in
    # OpenWFE::Json.encode and OpenWFE::Json.decode.
    #
    # In order the following JSON backends are attempted:
    #
    # * ActiveSupport - ActiveSupport::JSON
    # * JSON          - json/json_pure gems
    #
    # Your prefered JSON backend can be set using #prefered which
    # takes the backend name as a string. If the prefered backend
    # cannot be loaded, we'll fallback to loading the backends in
    # order of priority.
    #
    # If no backends are available, a #LoadError will be thrown once
    # any JSON encoding/decoding is attempted.
    #
    # IMPORTANT NOTE: ActiveSupport and the JSON gem don't play well
    # together. If you have ActiveSupport loaded the backend cannot be
    # changed to the JSON gem. Rather attempt to change the
    # ActiveSupport::JSON backend ( ActiveSupport 2.3.3 )
    #
    class Backend

      # Where keep our selected backends
      @available_backends = nil

      # Our list of backend options, in priority
      @priorities = ['ActiveSupport', 'JSON']

      # Our delegations map
      @delegates = {
        'JSON' => {
          :encode => 'generate', :decode => 'parse'
        },
        'ActiveSupport' => {
          :encode => 'encode', :decode => 'decode', :class => 'ActiveSupport::JSON'
        }
      }

      # Our proxy
      @proxy

      class << self

        attr_reader :priorities, :delegates

        # String array of the available backends on the system
        def available

          self.load_backends

          @available_backends
        end

        # A proxy object that delegates the encoding/decoding to the
        # appropriate backend. Will raise a LoadError if no backends
        # are available on the system.
        def proxy
          b = self.backend

          raise LoadError, 'No supported JSON backend detected' if b.nil?

          @proxy ||= BackendProxy.new( b )
        end

        # Return the first available backend, in order of priority, or
        # nil if none are available
        def backend

          self.load_backends.first
        end

        # Set the preferred backend, overwriting the order of
        # priority. If the preferred backend cannot be used, fallback
        # to the backend provided by #backend.
        def prefered=( name )

          self.load_backends

          if @available_backends && @available_backends.include?( name )
            if name == 'JSON' && @available_backends.include?( 'ActiveSupport' )
              name = 'ActiveSupport'
            end

            @proxy = BackendProxy.new( name )
          end
        end

        protected

        def load_backends
          return @available_backends unless @available_backends.nil?

          @priorities.each do |lib|
            begin
              next if lib == 'JSON' && defined?( ActiveSupport )

              require lib.downcase
              @available_backends ||= []
              @available_backends << lib

            rescue LoadError
              # Do nothing
            end
          end

          @available_backends
        end
      end
    end

    # Simple delegator that maps #encode and #decode to the selected
    # backend via the +delegates+ attribute on #Backend.
    class BackendProxy #:nodoc:

      attr_reader :backend, :klass

      def initialize( backend )
        @backend = backend

        klass = Backend.delegates[@backend][:class] || backend
        @klass = self.constantize( klass )

        raise ArgumentError, "Cannot find #{klass} to use as backend" if @klass.nil?
      end

      def encode( object )
        @klass.send( Backend.delegates[@backend][:encode], object )
      end

      def decode( string )
        @klass.send( Backend.delegates[@backend][:decode], string )
      end

      protected

      # Shamelessly lifted from the ActiveSupport::Inflector
      if Module.method(:const_get).arity == 1
        def constantize(camel_cased_word)
          names = camel_cased_word.split('::')
          names.shift if names.empty? || names.first.empty?

          constant = Object
          names.each do |name|
            return if constant.nil?
            constant = constant.const_defined?(name) ? constant.const_get(name) : nil
          end
          constant
        end
      else
        def constantize(camel_cased_word) #:nodoc:
          names = camel_cased_word.split('::')
          names.shift if names.empty? || names.first.empty?

          constant = Object
          names.each do |name|
            return if constant.nil?
            constant = constant.const_get(name, false) || nil
          end
          constant
        end
      end
    end
  end
end

