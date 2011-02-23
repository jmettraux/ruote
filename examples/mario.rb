
require 'thread'
  # for the Queue class

require 'rubygems'
require 'yajl'
require 'ruote'


PDEF = Ruote.process_definition do
  sequence do
    device :device => 4
    device :device => 7
  end
end

# Re-opening to add a #device method
#
class Ruote::Workitem

  def device

    params['device'] || fields['device']
  end
end

class AmqpParticipant
  include Ruote::LocalParticipant

  def consume(workitem)

    correlate(workitem)
    $queue << encode(workitem)
  end

  def cancel(fei, flavour)

    # no implementation for this example
  end

  protected

  def encode(workitem)

    Rufus::Json.encode({ 'type' => 2, 'device' => workitem.device })
  end

  def correlate(workitem)

    correlations =
      @context.storage.get('variables', 'correlations') ||
      { 'type' => 'variables', '_id' => 'correlations', 'data' => [] }

    correlations['data'] << [ workitem.device, workitem.fei.sid ]

    if r = @context.storage.put(correlations)
      #
      # put failed, race condition, have to redo
      #
      return correlate(workitem)
    end

    p [ :out, correlations ]
  end
end

class AmqpReceiver < Ruote::Receiver

  def initialize(engine, options={})

    super
    Thread.new { listen }
  end

  protected

  def listen

    loop do
      #sleep(rand * 0.1)
      msg = $queue.pop # blocking
      hsh = (Rufus::Json.decode(msg) rescue nil)
      p [ :receiver, hsh ]
      next if hsh == nil
      case hsh['type']
        when 1
          launch(PDEF)
        when 3
          correlate(msg, hsh)
        else
          $queue << msg # put back message
      end
    end
  end

  def correlate(msg, hsh)

    puts "received message from device #{hsh['device']}"

    correlations =
      @context.storage.get('variables', 'correlations') ||
      { 'type' => 'variables', '_id' => 'correlations', 'data' => [] }

    p [ :in, correlations ]

    correlation = correlations['data'].find { |cor| cor.first == hsh['device'] }

    if correlation

      correlations['data'].delete(correlation)

      if r = @context.storage.put(correlations)
        #
        # put failed, race condition, have to redo
        #
        return correlate(msg, hsh)
      end
      wi = workitem(correlation[1])
      reply_to_engine(wi) if wi
        # ignore 'unrelated' msgs
    else
      return # discard
      #$queue << msg # re-queue
        # this version simply discards unexpected messages
        # re-queueing... why not, could make the system busy...
    end
  end
end

class Devices

  def initialize
    @thread = Thread.new { listen }
  end

  def join
    @thread.join
  end

  protected

  def listen
    loop do
      #sleep(rand * 0.1)
      msg = $queue.pop # blocking
      hsh = (Rufus::Json.decode(msg) rescue nil)
      p [ :devices, hsh ]
      next if hsh == nil
      case hsh['type']
        when 2
          puts "device #{hsh['device']} received message..."
          $queue << Rufus::Json.encode(hsh.merge('type' => 3))
        else
          $queue << msg # put back message
      end
    end
  end
end

$engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))
$queue = Queue.new
$receiver = AmqpReceiver.new($engine)
$engine.register_participant :device, AmqpParticipant
$devices = Devices.new

$engine.noisy = true

$queue << Rufus::Json.encode({ 'type' => 1 })
$queue << Rufus::Json.encode({ 'type' => 1 })
$queue << Rufus::Json.encode({ 'type' => 1 })

$devices.join

