
#
# Testing ruote
#
# Fri Dec  4 17:15:10 JST 2009
#

require File.join(File.dirname(__FILE__), 'base.rb')


class Ruote::Worker
  def process_next_msg
    msg = @storage.get_msgs.first
    #p [ msg['action'], msg['fei'] ]
    process(msg) if msg
  end
end

class Ruote::Engine
  def process_next_msg (count=1)
    count.times { @context.worker.process_next_msg }
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

    @engine0.context[:noisy] = true
    @engine1.context[:noisy] = true
  end
end

