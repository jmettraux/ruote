
require 'rubygems'
  #
  # if ruote was installed via  sudo gem install ruote

#
# setting up a ruote engine, step by step

require 'openwfe/engine/fs_engine'
require 'openwfe/participants/participants'


#
# === the ENGINE itself
#

#application_context = {}

#application_context[:engine_name] = "my_engine"
  #
  # the default value for the name of an engine is 'engine'
  # this parameter is important when multiple engines do share some
  # communication channel (message queue for example)
  #
  # This value appears in the FlowExpressionId of all the expressions
  # and workitems of the engine.

#application_context[:work_directory] = "work"
  #
  # OpenWFEru engines take one optional argument : application_context
  #
  # the following engine constructions do not use this argument,
  # but you can make them use it
  #
  #   engine = OpenWFE::Engine.new(application_context)
  #
  # ...
  #

#application_context[:remote_definitions_allowed] = true
  #
  # unless this parameter is set to true, the engine will not accept
  # to launch processes whose definition is given by a URL, only
  # local process definitions (file:) or direct process definitions
  # will be allowed.

#application_context[:ruby_eval_allowed] = true
  #
  # if this parameter is set to true, evaluation of ruby code in process
  # definition strings will be allowed as well as the ruby version of
  # certain expression attributes like :
  #
  #   <participant name="${ruby:LDAP::lookup(customer_id)" />
  # or
  #   <if rtest="var % 2 == 0"> ...
  #

#application_context[:use_ruby_treechecker] = true
  #
  # by default, external ruby code (process definitions, ${r:...} snippets)
  # are checked before evaluation.
  # Turning this parameter to false, will disable that check.
  #
  # Turn this to false only if you have absolute trust in the ruby fragment
  # coming into the engine. But as they say in the armed forces
  #
  # "trusting is good, checking is better"
  #

#application_context[:dynamic_eval_allowed] = true
  #
  # by default, :dynamic_eval_allowed is not set to true, it means
  # that the "eval" expression cannot be used.
  #
  # don't set that unless you're sure you'll need this 'eval' expression.

#application_context[:definition_in_launchitem_allowed] = true
  #
  # by default (since 0.9.18), it's not allowed to launch processes whose
  # definitions is embedded in the launchitem. You have to explicitely
  # set this parameter to true


#engine = OpenWFE::Engine.new
#engine = OpenWFE::Engine.new(application_context)
  #
  # an in-memory, totally transient engine
  #
  # might be ideal for an embedded workflow engine with short lived
  # process definitions to run

engine = OpenWFE::FsPersistedEngine.new
#engine = OpenWFE::FsPersistedEngine.new(application_context)
  #
  # a file persisted engine, slow, used only within unit tests
  # do not use
  #
  # persistence is done by default under ./work/

at_exit do
  #
  # making sure that the engine gets properly stopped when
  # Ruby exits.
  #
  engine.stop
end

# -- a console

#engine.enable_irb_console
  #
  # by enabling the IRB console, you can jump into the engine object
  # with a CTRL-C hit on the terminal that runs hit.
  #
  # Hit CTRL-D to get out of the IRB console.

# -- process history

#require 'openwfe/expool/history'

#engine.init_service("history", InMemoryHistory)
  #
  # keeps all process history in an array in memory
  # use only for test purposes !

#engine.init_service("history", FileHistory)
  #
  # dumps all the process history in a file name "history.log"
  # in the work directory


#
# === some LISTENERS
#
# listeners 'receive' incoming workitems (InFlowWorkItem coming back from
# participants or LaunchItem requesting the launch of a particular flow)
#

#require 'openwfe/listeners/listeners'

#engine.add_workitem_listener(OpenWFE::FileListener, "500")
  #
  # listening for workitems (coming as within YAML files dropped in the
  # default ./work/in directory)
  #
  # check for new files every 500 ms

#require 'openwfe/listeners/sqslisteners'
#
#engine.add_workitem_listener(
#  OpenWFE::SqsListener.new(:wiqueue, engine.application_context),
#  "2s")
  #
  # adds a listener polling an Amazon Simple Queue Service (SQS)
  # named 'wiqueue' every 2 seconds
  #
  # http://jmettraux.wordpress.com/2007/03/13/openwferu-over-amazon-sqs/
  # http://aws.amazon.com/sqs


#
# === the PARTICIPANTS
#
# to learn more about participants :
# http://openwferu.rubyforge.org/participants.html
#

# you can use indifferently symbols or strings for participant names

# It's perhaps better to separate the participant registration and put
# it in its own .rb file, but anyway, here are some participant registration
# examples :

engine.register_participant(:toto) do |workitem|
  puts "toto received a workitem..."
  puts "lots of work..." if workitem.attributes.size > 3
  sleep 4
  puts "done."
end
  #
  # an example of a "block participant", binding Ruby code to a
  # participant in a business process

#require 'openwfe/participants/sqsparticipants'
#
#engine.register_participant(:sqs, OpenWFE::SqsParticipant.new(:wiqueue2))
  #
  # registers a participant named 'sqs', workitems for it will get placed
  # on the SQS queue named "wiqueue2"

#require 'openwfe/participants/socketparticipants'
#
#engine.register_participant(
#  "away", OpenWFE::SocketParticipant.new("target.host.co.jp", 7009))
  #
  # the participant "away" listens for workitems on port 7009 of
  # host 'target.host.co.jp', our SocketParticipant will dispatch
  # the workitem to it over TCP


engine.reload
  #
  # this method has to be called after all the participants have been
  # added, it looks for temporal expressions (sleep, cron, ...) to
  # reschedule.


#
# === joining the engine's scheduler thread
#
# (preventing the Ruby interpreting from prematurely (immediately) exiting)
#

engine.join
  #
  # you don't need to 'join' if the engine uses a listener, the thread of
  # the listener will prevent the Ruby interpreter from exiting.
  #
  # hit CTRL-C to quit (or maybe engine.enable_irb_console has been called,
  # in which case CTRL-C will bring you into a IRB console within the
  # engine itself).

