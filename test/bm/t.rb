
$:.unshift('lib')

require 'ruote/engine'

pdef = Ruote.process_definition do
  sequence do
    #625.times do
    #500.times do
    5000.times do
      echo 'a'
    end
  end
end

engine = Ruote::Engine.new
t = Time.now
fei = engine.launch(pdef)
engine.wait_for(fei.wfid)
puts "#{Time.now - t}s"

#require 'eventmachine'
#EM.run {
#  engine = Ruote::Engine.new
#  t = Time.now
#  fei = engine.launch(pdef)
#  #engine.wait_for(fei.wfid)
#  #puts "#{Time.now - t}s"
#  #EM.stop
#  engine.wqueue.observe(:processes) do |eclass, emsg, args|
#    puts "#{Time.now - t}s"
#    EM.stop
#  end
#}

