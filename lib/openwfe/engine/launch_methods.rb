#
#--
# Copyright (c) 2006-2009, John Mettraux, OpenWFE.org
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
# "made in Japan"
#
# John Mettraux at openwfe.org
#

module OpenWFE

  module LaunchMethods

    #
    # Launches a [business] process.
    # The 'launch_object' param may contain either a LaunchItem instance,
    # either a String containing the URL of the process definition
    # to launch (with an empty LaunchItem created on the fly).
    #
    # The launch object can also be a String containing the XML process
    # definition or directly a class extending OpenWFE::ProcessDefinition
    # (Ruby process definition).
    #
    # Returns the FlowExpressionId instance of the expression at the
    # root of the newly launched process.
    #
    # Options for scheduled launches like :at, :in and :cron are accepted
    # via the 'options' optional parameter.
    # For example :
    #
    #   engine.launch(launch_item)
    #     # will launch immediately
    #
    #   engine.launch(launch_item, :in => "1d20m")
    #     # will launch in one day and twenty minutes
    #
    #   engine.launch(launch_item, :at => "Tue Sep 11 20:23:02 +0900 2007")
    #     # will launch at that point in time
    #
    #   engine.launch(launch_item, :cron => "0 5 * * *")
    #     # will launch that same process every day,
    #     # five minutes after midnight (see "man 5 crontab")
    #
    # === :wait_for
    #
    # If you really need that, you can launch a process and wait for its
    # termination (or cancellation or error) as in :
    #
    #   engine.launch(launch_item, :wait_for => true)
    #     # will launch and return only when the process is over
    #
    # Note that if you set the option :wait_for to true, a triplet will
    # be returned instead of just a FlowExpressionId.
    #
    # This triplet is composed of [ message, info, fei ]
    # where message is :terminate, :error or :cancel and info contains
    # either the workitem, the error or a wfid, respectively.
    #
    # See http://groups.google.com/group/openwferu-users/browse_frm/thread/ffd0589bdc877765 for more about this triplet.
    #
    # (Note that the current implementation of this :wait_for will return if
    # any error was found. Thus, if an error occurs in a concurrent branch
    # and the other branch goes on, the launch() will return, even if the
    # rest of the process is continuing).
    #
    def launch (launchobject, options={})

      launchitem = to_launchitem(launchobject)

      wait = (options.delete(:wait_for) == true)
      initial_variables = options.delete(:vars) || options.delete(:variables)

      #
      # prepare raw expression

      raw_expression = prepare_raw_expression(launchitem)
        #
        # will raise an exception if there are requirements
        # and one of them is not met

      raw_expression.new_environment(initial_variables)
        #
        # as this expression is the root of a new process instance,
        # it has to have an environment for all the variables of
        # the process instance
        #
        # (new_environment() calls store_itself on the new env)

      raw_expression = wrap_in_schedule(raw_expression, options) \
        if (options.keys & [ :in, :at, :cron, :every ]).size > 0

      fei = raw_expression.fei

      #
      # apply prepared raw expression

      wi = InFlowWorkItem.new
      wi.attributes = launchitem.attributes.dup

      if wait
        wait_for(fei) { get_expression_pool.launch(raw_expression, wi) }
      else
        get_expression_pool.launch(raw_expression, wi)
        fei.dup # returns a copy, not the real one
      end
    end

    #
    # When 'parameters' are used at the top of a process definition, this
    # method can be used to assert a launchitem before launch.
    # An expression will be raised if the parameters do not match the
    # requirements.
    #
    # Note that the launch method will raise those exceptions as well.
    # This method can be useful in some scenarii though.
    #
    def pre_launch_check (launchitem)

      prepare_raw_expression(launchitem)
    end

    protected

    #
    # This method is called by the launch method. It's actually the first
    # stage of that method.
    # It may be interessant to use to 'validate' a launchitem and its
    # process definition, as it will raise an exception in case
    # of 'parameter' mismatch.
    #
    # There is a 'pre_launch_check' alias for this method in the
    # Engine class.
    #
    def prepare_raw_expression (launchitem)

      wfdurl = launchitem.workflow_definition_url

      definition, in_launchitem = if (not wfdurl)

        [ launchitem.attributes.delete('__definition'), true ]

      elsif wfdurl[0, 6] == 'field:'

        [ launchitem.attributes.delete(wfdurl[6..-1]), true ]

      else

        [ read_uri(wfdurl), false ]
      end

      raise(
        "didn't find process definition at '#{wfdurl}'"
      ) unless definition

      raise(
        ":definition_in_launchitem_allowed not set to true, cannot launch."
      ) if in_launchitem and ac[:definition_in_launchitem_allowed] != true

      raw_expression = get_expression_pool.build_raw_expression(
        definition, launchitem)

      # grrr... I hate this parameter checking, feels like static typing

      raw_expression.check_parameters(launchitem)
        #
        # will raise an exception if there are requirements
        # and one of them is not met

      raw_expression.store_itself

      raw_expression
    end

    #
    # Turns the raw launch request info into a LaunchItem instance.
    #
    def to_launchitem (o)

      return o if o.is_a?(OpenWFE::LaunchItem)
      return OpenWFE::LaunchItem.new(o) unless o.is_a?(String)

      li = OpenWFE::LaunchItem.new

      if %w{ < [ - }.include?(o.strip[0, 1]) or o.match(/\s/)
        #
        # XML, JSON or YAML or not a URI
        #
        li.definition = o
      else
        #
        # it's a URI
        #
        li.definition_url = o
      end

      li
    end

  end
end

