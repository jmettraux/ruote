#--
# Copyright (c) 2008-2009, Torsten Schönebaum, John Mettraux (OpenWFE.org)
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
# Made in Europe and Japan.
#++


require 'activeresource' # gem activeresource

require 'openwfe/participants/participants'


module OpenWFE
  module Extras

    #
    # Ruote participant which does a REST call. It's using ActiveResource to do
    # the actual magic. You can call every class and instance method
    # ActiveResource::Base and its mixins provide. You can also process the
    # response of the REST request and save some of its data into the workitem
    # for example.
    #
    # Before using this participant you *really* should make yourself familiar
    # with ActiveResource and its usage.
    #
    # ==Using it
    #
    # The participant should be registered in the engine in a way like this:
    #
    #   engine.register_participant(
    #     'reminder',
    #     ActiveResourceParticipant.new(
    #       {
    #         :site => 'http://localhost:7000',
    #         :resource_name => 'story',
    #         :method => 'put', # we will use ActiveResource::CustomMethods::InstanceMethods#put
    #         :argument => 'send_reminder', # put is happy with just one
    #                                       # parameter: The action to be
    #                                       # called. So we won't have to use a
    #                                       # block to set the arguments of the
    #                                       # ActiveResource method to call.
    #       }
    #     )
    #   )
    #
    # Let's try a more complex example:
    #
    #   engine.register_participant(
    #     'complex_ares',
    #     ActiveResourceParticipant.new(
    #       {
    #         :site => 'http://localhost:7000',
    #         :resource_name => 'story',
    #         :method => 'find', # yes, even ActiveResource::Base#find method
    #                            # may be used...
    #         :response_handling => proc do |response, workitem| # define response
    #                                                            # handling block
    #           workitem.set_attribute('title', response.attributes['title'])
    #                            # The type of the response object depends on
    #                            # the method you use!
    #         end
    #       }
    #     ) do |workitem| # define arguments to use with the find method
    #       # each argument is an entry in an array the block has to return
    #       [
    #          workitem.attributes['story_id'], # the first argument
    #          {:prefix => 'foo'} # the second one is an hash
    #       ]
    #     end
    #   )
    #
    # You can now use the participant in your workflow definitions. An example
    # using XML:
    #
    #     <concurrence count="1">
    #       <participant ref="qa" />
    #       <cron every="1m">
    #         <participant
    #           ref="reminder"
    #           site="http://localhost:7000"
    #           resource_name="story"
    #           method="put"
    #           action="send_reminder"
    #           resource_id="${field:story_id}" />
    #       </cron>
    #     </concurrence>
    #
    # Here, the ActiveResourceParticipant is used to send a reminder.
    #
    # *Note:* prefer configuration of the participant at registration time,
    # information like 'method', 'site' and 'resource_name' may clutter the
    # process definition.
    #
    class ActiveResourceParticipant
      include OpenWFE::LocalParticipant

      #
      # == options hash
      #
      # You have to set some default options by passing an options hash to the
      # new method. It should contain the following keys:
      #
      # <tt>:site</tt>:: The URI (as string) of the site where your REST
      #   interface sits. See <tt>site</tt> parameter in ActiveResource::Base.
      # <tt>:resource_name</tt>:: The name of the resource you like to access.
      #   See <tt>element_name</tt> parameter in ActiveResource::Base.
      # <tt>:method</tt>:: The ActiveResource method to call. In most cases
      #   should be "get", "put", "post" or "delete".
      # <tt>:argument</tt>:: The first parameter which should be used as
      #   argument to the ActiveResource method which will be called. This value
      #   is ignored if a block is given (see below)
      # <tt>:resource_id</tt>:: The ID of the resource on which the action
      #   should be called on default. If negative, nil or false, the action
      #   will be called on the complete set of resources instead of on a single
      #   resource determined by its ID.
      # <tt>:response_handling</tt>:: A proc object / block which gets called
      #   after the request is done. It gets called with to arguments: The
      #   response of the ActiveResource method called and the workitem.
      #
      # The new method also takes a block. It may be used to set the arguments
      # of the ActiveResource method to call. The block must return an array of
      # arguments. The array will be splitted and each entry will be used as
      # argument to the ActiveResource method called. See
      # OpenWFE::LocalParticipant#call_block for the arguments the block itself
      # takes.
      #
      # All parameters except response_handling and the block set default values
      # -- you can always override them in the process definition. Just use the
      # corresponding symbol name (without ":") as attribute.
      #
      def initialize (options, &block)

        @options = options

        # some defaults
        @options[:site] ||= 'http://127.0.0.1:3000'
        @options[:method] ||= :get

        @block = block
      end

      #
      # This method is called each time the participant receives a workitem. It
      # calls the requested ActiveResource method, calls the response handling
      # code if present and then immediatly replies to the engine.
      #
      def consume (workitem)

        # use block to determine the method's arguments if given
        args = if @block
          call_block(@block, workitem)
        elsif a = param(workitem, :arg) || param(workitem, :argument)
          Array(a)
        else
          [] # no arguments
        end

        # create new subclass of ActiveResource::Base
        active_resource_class = Class.new(ActiveResource::Base)
        active_resource_class.site = param(workitem, :site) # set site parameter
        active_resource_class.element_name = param(workitem, :resource_name) # set element name

        # Do we work on a single or on a set of resources? If resource_id is nil
        # or negative, it's a set of resources.

        resource_id = param(workitem, :resource_id)

        active_resource = if (!resource_id) || (resource_id.to_i < 0)
          # set of resources
          active_resource_class
        else
          # specific resource
          active_resource_class.new(:id => resource_id)
        end

        response = active_resource.send(param(workitem, :method), args)

        # we got our response, but what to do with it?
        if (h = param(workitem, :response_handling)).is_a?(Proc)
          h.call(response, workitem)
        end

        # reply to the engine
        reply_to_engine(workitem)
      end

      protected

      def param (workitem, key)
        workitem.params[key] || @options[key]
      end
    end

  end
end
