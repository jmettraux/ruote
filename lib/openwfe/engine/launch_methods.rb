#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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
  # The methods for ordering an engine to read a process definition and
  # turn it into a process instance (launching).
  #
  module LaunchMethods

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
        get_expression_pool.wait_for(fei) {
          get_expression_pool.launch(raw_expression, wi)
        }
      else
        get_expression_pool.launch(raw_expression, wi)
        fei.dup # returns a copy, not the real one
      end
    end

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

    # Waits for a given process instance to terminate.
    # The method only exits when the flow terminates, but beware : if
    # the process already terminated, the method will never exit.
    #
    # The parameter can be a FlowExpressionId instance, for example the
    # one given back by a launch(), or directly a workflow instance id
    # (String).
    #
    # This method is mainly used in utests.
    #
    def wait_for (fei_or_wfid)

      wfid = if fei_or_wfid.kind_of?(FlowExpressionId)
        fei_or_wfid.workflow_instance_id
      else
        fei_or_wfid
      end

      get_expression_pool.wait_for(wfid)
    end

    protected

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

        [ get_def_parser.read_uri(wfdurl), false ]
      end

      raise(
        "didn't find process definition at '#{wfdurl}'"
      ) unless definition

      raise(
        ':definition_in_launchitem_allowed not set to true, cannot launch.'
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

    # If the launch method is called with a schedule option
    # (like :at, :in, :cron and :every), this method takes care of
    # wrapping the process with a sleep or a cron.
    #
    def wrap_in_schedule (raw_expression, options)

      oat = options[:at]
      oin = options[:in]
      ocron = options[:cron]
      oevery = options[:every]

      fei = FlowExpressionId.new_fei(
        :workflow_instance_id => get_wfid_generator.generate(nil),
        :workflow_definition_name => 'schedlaunch',
        :expression_name => 'sequence')

      # not very happy with this code, it builds custom
      # wrapping processes manually, maybe there is
      # a more elegant way, but for now, it's ok.

      template = if oat or oin

        sleep_atts = if oat
          { 'until' => oat }
        else #oin
          { 'for' => oin }
        end
        sleep_atts['scheduler-tags'] = "scheduled-launch, #{fei.wfid}"

        raw_expression.new_environment
        raw_expression.store_itself

        [
          'sequence', {}, [
            [ 'sleep', sleep_atts, [] ],
            raw_expression.fei
          ]
        ]

      elsif ocron or oevery

        fei.expression_name = 'cron'

        cron_atts = if ocron
          { 'tab' => ocron }
        else #oevery
          { 'every' => oevery }
        end
        cron_atts['name'] = "//cron_launch__#{fei.wfid}"
        cron_atts['scheduler-tags'] = "scheduled-launch, #{fei.wfid}"

        template = raw_expression.raw_representation
        remove(raw_expression)

        [ 'cron', cron_atts, [ template ] ]

      else

        nil # don't schedule at all
      end

      if template

        raw_exp = RawExpression.new_raw(
          fei, nil, nil, @application_context, template)

        #raw_exp.store_itself
        raw_exp.new_environment

        raw_exp
      else

        raw_expression
      end
    end

  end
end

