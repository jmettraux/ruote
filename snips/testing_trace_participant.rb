
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

engine.register do
  catchall TestParticipant
end

