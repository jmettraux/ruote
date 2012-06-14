
require 'ruote'

#
# dashboard initialization

$ruote = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
$ruote.noisy = ENV['NOISY'] == 'true'

#
# the participants

class Administrator
  include Ruote::LocalParticipant

  def on_workitem

    if ENV['NOISY'] == 'true'
      puts '-' * 80
      p $ruote.ps(workitem.wfid)
      puts '-' * 80
    end

    puts "* administrator: timers: #{workitem.fields['admin_timers'].inspect}"

    # doesn't reply
  end

  def on_cancel

    # empty
  end
end

class Evaluator
  include Ruote::LocalParticipant

  def on_workitem

    s = ''

    while ! s.match(/^[dlh]/)
      print "* evaluator: (d)one/(l)ow/(h)igh? "
      s = gets
    end

    workitem.fields['answer'] = 'none'
    case s
      when /^d/
        workitem.fields['answer'] = 'done'
      when /^l/
        workitem.fields['admin_timers'] = '20d: reminder, 21d: timeout'
      else
        workitem.fields['admin_timers'] = '1h: reminder, 2d: timeout'
    end

    reply
  end

  def on_cancel

    # empty
  end
end

$ruote.register do
  administrator Administrator
  evaluator Evaluator
end

#
# the process definition

pdef = Ruote.define do

  set 'admin_timers' => '20d: reminder, 21d: timeout'
  cursor do
    concurrence :wait_for => 'ev' do
      administrator :timers => '${admin_timers}'
      evaluator :tag => 'ev'
    end
    rewind :unless => '${answer} == done'
  end

  define 'reminder' do
    # ...
  end
end

#
# run it

wfid = $ruote.launch(pdef)
$ruote.wait_for(wfid, -1)

