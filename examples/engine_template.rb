
require 'rubygems'
    #
    # if OpenWFEru was installed via 'gem'

#
# setting up an OpenWFEru engine, step by step

require 'openwfe/engine/engine'
require 'openwfe/engine/file_persisted_engine'
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
    #     engine = OpenWFE::Engine.new(application_context)
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
    #     <participant name="${ruby:LDAP::lookup(customer_id)" />
    # or
    #     <if rtest="var % 2 == 0"> ...
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

#engine = OpenWFE::FilePersistedEngine.new
#engine = OpenWFE::FilePersistedEngine.new(application_context)
    #
    # a file persisted engine, slow, used only within unit tests
    # do not use

engine = OpenWFE::CachedFilePersistedEngine.new
#engine = OpenWFE::CachedFilePersistedEngine.new(application_context)
    #
    # a file persisted engine, with an in-memory cache.
    # use that
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

# -- process journaling

#require 'openwfe/expool/journal'
#engine.init_service("journal", Journal)
    #
    # activates 'journaling',
    #
    # see http://openwferu.rubyforge.org/journal.html
    #
    # Journaling has a cost in terms of performace.
    # Journaling should be used only in case you might want to migrate
    # [segments of] running processes.
    #
#engine.application_context[:keep_journals] = true
    #
    # if set to true, the journal of terminated processes will be kept
    # (but moved by default to ./work/journal/done/)


#
# === some LISTENERS
#
# listeners 'receive' incoming workitems (InFlowWorkItem coming back from
# participants or LaunchItem requesting the launch of a particular flow)
#

#require 'openwfe/listeners/listeners'

#sl = OpenWFE::SocketListener.new(
#    "socket_listener", @engine.application_context, 7008)
#engine.add_workitem_listener(sl)
    #
    # adding a simple SocketListener on port 7008

#require 'openwfe/listeners/socketlisteners'
#
#engine.add_workitem_listener(OpenWFE::SocketListener)
    #
    # adding a SocketListener on the default port 7007

#engine.add_workitem_listener(OpenWFE::FileListener, "500")
    #
    # listening for workitems (coming as within YAML files dropped in the
    # default ./work/in directory)
    #
    # check for new files every 500 ms

#require 'openwfe/listeners/sqslisteners'
#
#engine.add_workitem_listener(
#    OpenWFE::SqsListener.new(:wiqueue, engine.application_context),
#    "2s")
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
#    "away", OpenWFE::SocketParticipant.new("target.host.co.jp", 7009))
    #
    # the participant "away" listens for workitems on port 7009 of
    # host 'target.host.co.jp', our SocketParticipant will dispatch
    # the workitem to it over TCP


engine.reschedule
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

