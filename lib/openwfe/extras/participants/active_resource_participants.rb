#
# #--
# Copyright (c) 2008, Torsten Schönebaum, John Mettraux (OpenWFE.org)
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
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. #++
#

#
# "made in Europe and Japan"
#
# Torsten Schönebaum and John Mettraux (openwfe.org)
#



require 'activeresource' # gem activeresource

require 'openwfe/participants/participants'


module OpenWFE
  module Extras

    #
    # Ruote participant which does a REST call. It's using ActiveResource to do
    # the actual magic. You can call every class and instance method
    # ActiveResource::Base and its mixins provide. You can also process the
    # response of the REST request and save some of it's data into the workitem
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
    #         :argument => 'send_reminder', # put is happy with just one parameter: The action to be called. So we won't have to use a block to set the arguments of the ActiveResource method to call.
    #       }
    #     )
    #   )
    #
    # Let's try a more complex example:
    #
    #   engine.register_participant(
    #     'complex_ar',
    #     ActiveResourceParticipant.new(
    #       {
    #         :site => 'http://localhost:7000',
    #         :resource_name => 'story',
    #         :method => 'find', # yes, even ActiveResource::Base#find method may be used...
    #         :response_handling => proc do |response, workitem| # define response handling block
    #           workitem.set_attribute('title', response.attributes['title']) # The type of the response object depends on the method you use!
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
    # Note : prefer configuration of the participant at registration time,
    # information like 'method', 'site' and 'resource_name' may clutter
    # the process definition.
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
      #   after the request is done. It get's called with to arguments: The
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
