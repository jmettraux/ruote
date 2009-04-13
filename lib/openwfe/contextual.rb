#--
# Copyright (c) 2006-2009, John Mettraux, Nicolas Modrzyk OpenWFE.org
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


module OpenWFE

  #
  # This mixin helds an application_context field and provides a
  # lookup method for digging into that context.
  #
  module Contextual

    attr_accessor :application_context

    alias :ac :application_context

    #
    # Looks up something in the application context, if the given
    # key is a class, then the first value in the context of that
    # class is returned.
    #
    def lookup (key)

      if key.kind_of?(Class)
        @application_context.each do |k, value|
          return value if value.class == key
        end
        return nil
      end

      @application_context[key]
    end

    #
    # Use reflection to instantiate the new service,and
    # add it to the application context
    # The service_name can be a String or a Symbol (which will be
    # turned into a String).
    #
    def init_service (service_name, service_class)

      if service_name
        #
        # if there is a service previously registered under the same name,
        # make sure to stop before it gets 'overriden' in the
        # application context

        s = @application_context[service_name]
        s.stop if s.respond_to?(:stop)
      end

      s = service_class.new(service_name, @application_context)

      unless service_name
        #
        # making sure to register the service. service#new doesn't
        # register when there is no service_name

        s.service_name = "#{service_class.name}::#{s.object_id}"
        @application_context[s.service_name.to_s] = s
      end

      s
    end

    #
    # Returns the work directory for the ruote application context (if any).
    #
    def get_work_directory (context_or_dir=nil)

      dir = if context_or_dir.is_a?(String)
        context_or_dir
      elsif context_or_dir.respond_to?(:[])
        context_or_dir[:work_directory]
      else
        @application_context[:work_directory] if @application_context
      end

      dir = DEFAULT_WORK_DIRECTORY unless dir

      FileUtils.makedirs(dir) unless File.exist?(dir)

      copy_pooltool(dir)

      dir
    end

    protected

    def copy_pooltool (dir)
      target = dir + '/pooltool.ru'
      return if File.exist?(target)
      source = File.dirname(__FILE__) + '/../pooltool.ru'
      FileUtils.cp(source, target)
    end

  end
end

