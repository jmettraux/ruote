
require 'rubygems'
require 'ruote'


# our ruote engine
#
engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))


# some participants

class TestParticipant
  include Ruote::LocalParticipant

  def consume(workitem)

    puts(' * ' + workitem.participant_name)

    reply_to_engine(workitem)
  end
end

class TestCentral
  include Ruote::LocalParticipant

  TASKS = %w[
    coast_pickup mountain_pickup coast_pickup get_back_to_depot
  ]

  def consume(workitem)

    workitem.fields['next_task'] = TASKS.shift

    reply(workitem)
  end
end

# registering the participants
#
engine.register do

  central TestCentral
    # the 'central' participant points to TestCentral

  catchall TestParticipant
    # all unknown participants are handled by TestParticipant instances
end


# our process definition
#
pdef = Ruote.process_definition do

  define 'get_next_task' do
    participant 'central'
  end

  define 'coast_pickup' do
    participant 'coast'
  end
  define 'mountain_pickup' do
    participant 'mountain'
  end
  define 'get_back_to_depot' do
    participant 'depot'
  end

  sequence do # body of the process

    cursor do
      subprocess 'get_next_task'
      subprocess '${next_task}'
      rewind :unless => '${next_task} == get_back_to_depot'
        # cursor rewinds unless next task is getting back to depot
    end
  end
end

wfid = engine.launch(pdef)

engine.wait_for(wfid)
  # exit only when the process terminates

