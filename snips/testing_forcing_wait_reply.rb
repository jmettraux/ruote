
require 'rubygems'
require 'ruote'

pdef = Ruote.process_definition do
  sequence do
    wait '5m'
    alpha
  end
end

class EchoParticipant
  def consume(workitem)
    p workitem
  end
end

engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))

engine.register do
  alpha EchoParticipant
end

wfid = engine.launch(pdef)

sleep 0.400
  # making sure the wait expression has been reached

waiter = engine.process(wfid).expressions.find { |fe| fe.name == 'wait' }
  # grab the wait[ing] expression

engine.reply(waiter.h.applied_workitem)
  # simply forcing the reply

sleep 0.400
  # giving it a bit of time

