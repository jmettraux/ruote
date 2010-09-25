
# http://gist.github.com/596822

require 'rubygems'
require 'ruote'

pdef = Ruote.process_definition do
  repeat do
    ping # mister ping, please shoot first
    pong
  end
end

class Opponent
  include Ruote::LocalParticipant

  def initialize (options)
    @options = options
  end

  def consume (workitem)
    puts @options['sound']
    reply_to_engine(workitem)
  end
end

engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))

engine.register_participant :ping, Opponent, 'sound' => 'ping'
engine.register_participant :pong, Opponent, 'sound' => 'pong'

wfid = engine.launch(pdef)

sleep 5 # five seconds of ping pong fun

engine.cancel_process(wfid) # game over

