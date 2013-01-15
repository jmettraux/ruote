require 'rufus-json/automatic'
require 'ruote'
require 'ruote/storage/fs_storage'


#
# Preparing the engine

# The ruote onion:
# * storage at the core
# * a worker tied to the storage
# * a dashboard with all the levers as the outer layer
#
# This storage uses the filesystem to persist all the ruote messages, workitems,
# etc...
#
# Placing the onion in a convenient 'ruote' local variable.

ruote = Ruote::Dashboard.new(
  Ruote::Worker.new(
    Ruote::FsStorage.new('ruote_work')))

ruote.noisy = ENV['NOISY'] == 'true'
  #
  # if the env variable NOISY is set to 'true', the engine activity will
  # be detailed on $stdout.


#
# Defining participants

# Three kinds of participants, logistics, scouts and leaders.
# Logistics prepare the materail for scouts, scouts go out and count birds,
# leaders compile a report

class Logistics < Ruote::Participant

  def on_workitem

    puts
    puts "prepare for a #{workitem.fields['bird']} photo hunt..."
    puts
    workitem.fields['spotted'] = []

    reply
  end
end

class Scout < Ruote::Participant

  def on_workitem

    sleep(rand)
    result = [ workitem.participant_name, (20 * rand + 1).to_i ]
    workitem.fields['spotted'] << result
    p result

    reply
      #
      # participant work done, call #reply to give back the workitem to ruote
      # and let the flow move on
  end
end

class Leader < Ruote::Participant

  def on_workitem

    workitem.fields['total'] = workitem.fields['spotted'].inject(0) { |t, f|
      t + f[1]
    }
    puts
    puts "bird:    " + workitem.fields['bird']
    puts "spotted: " + workitem.fields['spotted'].inspect
    puts "total:   " + workitem.fields['total'].inspect
    puts

    # TODO: upload to Google spreadsheet

    reply
  end
end


#
# Registering participants

# Mapping participant names to participant classes.

ruote.register /^scout_/, Scout
ruote.register /^leader_/, Leader
ruote.register 'logistics', Logistics


#
# Defining a process

# This is the Doug team's process, simply send out Alice, Bob and Charly to
# count the birds and then Doug compiles the report.
#
# The merge_type concats the workitem fields that are arrays. In our case
# the resulting 'spotted' field is the concatenation of the three 'spotted'
# fields emitted by each scout.

# The process definition is written in 'radial', a mini language understood
# by ruote.

pdef = %q{
  define
    logistics
    concurrence merge_type: concat
      scout_alice
      scout_bob
      scout_charly
    leader_doug
}

# If you hate significant indentation, you can use plain Ruby, thanks to
# Ruote.define:

#pdef = Ruote.define do
#  concurrence :merge_type => :concat do
#    scout_alice
#    scout_bob
#    scout_charly
#  end
#  leader_doug
#end


#
# Launching, creating a process instance

# For this quickstart, we only launch 1 instance of the process (and wait
# for it to end).
#
# The #launch method accepts a process definition and an optional list of
# initial workitem fields.
#
# Ruote is mostly a process definition interpreter. You can call launch
# multiple times with different combinations of definitions and fields and
# ruote will run multiple process/workflow instances.

wfid = ruote.launch(
  pdef,
  'bird' => %w[ thrush cardinal dodo ].shuffle.first)

ruote.wait_for(wfid)
  #
  # Blocks current thread until our process instance terminates
  #
  # This wait_for is mainly used in tests (and demos), you usually don't
  # want to wait_for flows, they are asynchronous beasts and they get back
  # to you (via a participant or a process observer)

