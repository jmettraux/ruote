
# A ruote demo for
# http://www.quora.com/Which-workflow-management-system-does-the-following

require 'rubygems'

require 'fileutils'

require 'ruote' # gem install ruote
require 'ruote/storage/fs_storage'

#
# start a ruote workflow engine, with file based persistence (in dir work/)

$dashboard = Ruote::Dashboard.new(
  Ruote::Worker.new(
    Ruote::FsStorage.new('work')))

#
# participant implementation, for this demo, it merely emits a message
# and then immediately replies to the workflow engine

class DemoParticipant
  include Ruote::LocalParticipant

  def consume(workitem)

    puts(
      "... participant #{workitem.participant_name}" +
      " processing data in file #{workitem.fields['datafile']}")

    reply_to_engine(workitem) # participant's work is done
  end

  def cancel(fei, flavour)

    # empty for this demo
  end
end

#
# the workflow (process) definition

## 2) Task A starts when item 1) is satisfied
## 3) Task B starts when Task A has successfully completed
## 4) Task A is retried if it failed previously (number of retries limited)
## 5) Runs tasks in background or submits to batch system
## 6) Has an undo feature; say Task B is modified, can previous results
##    for Task B be undone and rerun with previous results from Task A

PDEF = Ruote.process_definition do
  sequence do

    task_a :on_error => 'redo'

    sequence :tag => 'final_stage' do
      task_b
      _redo 'final_stage', :if => '${b_not_ok}'
    end
  end
end
  # note that I didn't address the "number of retries limited" spec,
  # kept it for a future iteration

#
# instances of DemoParticipant do the task handling, let's map
# task_.+ to DemoParticipant in the ruote engine

$dashboard.register do
  participant 'task_.+', DemoParticipant
end

#
# the in/ dir is where data files arrive
# the seen/ one is where they are placed when their data is processed

FileUtils.mkdir('in') rescue nil
FileUtils.mkdir('seen') rescue nil

#
# the dir watching loop, Ruby has many dir watching libraries, but for this
# demo, let's just iterate and then sleep 5 seconds

## 1) Invokes the workflow when a data file exists and has a certain age
##    (to guarantee that file transfer has completed)

loop do

  puts '.'

  Dir['in/*.data'].each do |filepath|

    next if Time.now - File.mtime(filepath) < 20
      # skip if file has been modified less than 20 seconds ago

    seen = 'seen/' + File.basename(filepath)

    FileUtils.mv(filepath, seen)

    process_id = $dashboard.launch(PDEF, 'datafile' => seen)
      # launch a workflow instance for our datafile

    puts ".. launched process #{process_id}"
  end

  sleep 5 # seconds
end

# run this ruby script and feed it by placing .data files in the in/ dir...

