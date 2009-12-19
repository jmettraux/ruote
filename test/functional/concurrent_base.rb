
#
# Testing ruote
#
# Fri Dec  4 17:15:10 JST 2009
#

require File.join(File.dirname(__FILE__), 'base.rb')


class Ruote::Worker

  def step_by_one
    msg = @storage.get_msgs.first
    #p [ msg['action'], msg['fei'] ]
    if msg
      process(msg)
    else
      false
    end
  end

  public :process

  def step_until (&block)
    loop do
      msg = @storage.get_msgs.first
      return msg if block.call(msg)
      process(msg)
    end
  end
end

class Ruote::Engine
  def step (count=1)
    count.times { @context.worker.step_by_one }
  end
  def step!
    r = @context.worker.step_by_one
    step! if r == false
  end
  def walk
    while @context.worker.step_by_one do; end
  end
  def do_step (msg)
    @context.worker.process(msg)
  end
  def step_until (&block)
    @context.worker.step_until(&block)
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

