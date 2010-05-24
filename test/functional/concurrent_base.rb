
#
# Testing ruote
#
# Fri Dec  4 17:15:10 JST 2009
#

require File.join(File.dirname(__FILE__), 'base.rb')


class Ruote::Worker

  public :process
end

class Ruote::Engine

  def peek_msg
    @msgs = @context.storage.get_msgs if ( ! @msgs) || @msgs.size < 1
    @msgs.shift
  end

  def do_process (msg)
    @context.worker.process(msg)
  end

  def step (count)
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

    @storage = determine_storage(
      's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ])

    @engine0 = Ruote::Engine.new(Ruote::Worker.new(@storage), false)
    @engine1 = Ruote::Engine.new(Ruote::Worker.new(@storage), false)
      #
      # the 2 engines are set with run=false

    @tracer0 = Tracer.new
    @tracer1 = Tracer.new

    @engine0.context.add_service('s_tracer', @tracer0, nil)
    @engine1.context.add_service('s_tracer', @tracer1, nil)

    @engine1.context.logger.color = '32' # green
  end

  def teardown

    @storage.purge!

    @engine0.shutdown
    @engine1.shutdown
  end

  protected

  def noisy

    @engine0.context.logger.noisy = true
    @engine1.context.logger.noisy = true
  end
end

