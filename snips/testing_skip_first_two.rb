
require 'rubygems'
require 'ruote'

class TestParticipant
  include Ruote::LocalParticipant

  def self.trace
    (@trace ||= [])
  end

  def initialize(opts)
    @opts = []
  end

  def consume(workitem)

    self.class.trace << [ Time.now, workitem.dup ]
      # this is a full dup

    reply_to_engine(workitem)
  end
end

engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))

engine.register do
  participant 'alpha_.+', TestParticipant
  catchall Ruote::StorageParticipant
end

engine.launch(Ruote.process_definition do
  sequence do
    alpha_one
    alpha_two
    bravo_three
  end
end)

engine.wait_for(:bravo_three)

p TestParticipant.trace.collect { |t, w| w.participant_name }
  # => ["alpha_one", "alpha_two"]
p engine.storage_participant.first.participant_name
  # => "bravo_three"

