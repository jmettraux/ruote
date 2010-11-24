
require 'rubygems'
require 'ruote'

class Charly
  include Ruote::LocalParticipant

  def consume(workitem)
    raise 'gone wrong'
  end
end

engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))

#engine.noisy = true

engine.register do
  charly Charly
  catchall Ruote::StorageParticipant
end

pdef = Ruote.process_definition do
  concurrence do
    alpha
    bravo
    sequence do
      charly
      delta
    end
  end
end

wfid = engine.launch(pdef)
engine.wait_for(wfid)

ps = engine.process(wfid)

ps.expressions.each do |exp|
  p [ exp.name, exp.fei.sid ]
end
  #
  # ["define", "0!!20101124-fubunije"]
  # ["concurrence", "0_0!!20101124-fubunije"]
  # ["participant", "0_0_0!!20101124-fubunije"]
  # ["participant", "0_0_1!!20101124-fubunije"]
  # ["sequence", "0_0_2!!20101124-fubunije"]
  # ["participant", "0_0_2_0!!20101124-fubunije"]

