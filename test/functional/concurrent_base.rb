
#
# Testing ruote
#
# Fri Dec  4 17:15:10 JST 2009
#

require File.expand_path('../base', __FILE__)


class Ruote::Worker

  public :process
end

class Ruote::Engine

  def peek_msg
    if ( ! @msgs) || @msgs.size < 1
      @msgs = @context.storage.get_msgs
    end
    @msgs.shift
  end

  def do_process(msg)
    @context.worker.process(msg)
  end

  def step(count)
    return if count == 0
    loop do
      m = next_msg
      next unless m
      do_process(m)
      break
    end
    step(count - 1)
  end

  def next_msg
    loop do
      if m = peek_msg
        return m
      end
    end
  end

  def gather_msgs
    (1..77).to_a.inject({}) { |h, i|
      #(i % 10).times { Thread.pass }
      sleep 0.001
      sleep 0.025 # couch :-(
      m = peek_msg
      h[m['_id']] = m if m
      h
    }.values.sort { |a, b|
      a['put_at'] <=> b['put_at']
    }
  end
end


module ConcurrentBase

  def setup

    @storage = determine_storage({})

    @dashboard0 = Ruote::Engine.new(Ruote::Worker.new(@storage), false)
    @dashboard1 = Ruote::Engine.new(Ruote::Worker.new(@storage), false)
      #
      # the 2 engines are set with run=false

    @tracer0 = Tracer.new
    @tracer1 = Tracer.new

    @dashboard0.context.add_service('s_tracer', @tracer0, nil)
    @dashboard1.context.add_service('s_tracer', @tracer1, nil)

    @dashboard1.context.logger.color = '32' # green

    noisy if ENV['NOISY'] == 'true'
  end

  def teardown

    @storage.purge!

    @dashboard0.shutdown
    @dashboard1.shutdown
  end

  protected

  def noisy

    @dashboard0.noisy = true
    @dashboard1.noisy = true
  end
end

