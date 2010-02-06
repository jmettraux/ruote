
#
# testing ruote
#
# Wed Jul  8 15:30:55 JST 2009
#

require File.join(File.dirname(__FILE__), 'concurrent_base')

#require 'ruote/part/hash_participant'


class CtConcurrenceTest < Test::Unit::TestCase
  include ConcurrentBase

  def test_collision

    pdef = Ruote.process_definition do
      concurrence do
        echo 'a'
        echo 'b'
      end
    end

    #noisy

    wfid = @engine0.launch(pdef)
    @engine0.step 4

    msgs = @storage.get_msgs
    $stderr.puts "*cough*" if msgs.size != 2
    #msgs.each do |m|
    #  p [ m['action'], m['fei']['expid'], m['workitem'] ]
    #end

    t0 = Thread.new { @engine1.step! }
    t1 = Thread.new { @engine0.step! }
    t0.join
    t1.join

    #t0 = Thread.new { @engine1.step }
    #@engine0.step
    #t0.join

    msgs = @storage.get_msgs
    msg = msgs.first

    if msgs.size > 1 || (msg && msg['fei'] && msg['fei']['expid'] != '0')

      msgs.each do |m|

        fei = m['fei'] ?
          Ruote::FlowExpressionId.to_storage_id(m['fei']) : ''
        wi_fei = m['workitem'] ?
          Ruote::FlowExpressionId.to_storage_id(m['workitem']['fei']) : ''

        p [ m['action'], fei, wi_fei ]
      end
    end

    if msg['action'] == 'error_intercepted'
      #p @engine0.process(wfid).errors.first
      puts @engine0.process(wfid).errors.first.message
      puts @engine0.process(wfid).errors.first.trace
    end

    assert_equal 1, msgs.size
    assert_equal 'reply', msg['action']
    assert_equal '0', msg['fei']['expid']
  end
end

