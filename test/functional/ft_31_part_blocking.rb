
#
# testing ruote
#
# Fri Sep 25 16:15:57 JST 2009
#
# By David Goldhirsch
#

require File.join(File.dirname(__FILE__), 'base')

class FtPartBlockingTest < Test::Unit::TestCase
 include FunctionalBase

 def test_equal_time_favors_first
   run_engine
   assert_equal 'first', @tracer.to_s
 end

 def test_second_is_faster
   #noisy
   run_engine :first_time => 0.5
   assert_equal 'second', @tracer.to_s
 end

 def test_first_is_faster
   run_engine  :second_time => 0.5
   assert_equal 'first', @tracer.to_s
 end

 protected

 def run_engine (options={})

   @engine.context.stash[:first_time] = options[:first_time] || 0.0
   @engine.context.stash[:second_time] = options[:second_time] || 0.0

   if @engine.context.stash[:first_time] == @engine.context.stash[:second_time]
     @engine.context.stash[:second_time] = @engine.context.stash[:first_time] + 0.1
   end

   pdef = Ruote.process_definition :name => 'simple' do
     sequence do
       concurrence do # spec says this is equivalent to :count => 1
         participant :ref => 'first'
         participant :ref => 'second'
       end
       participant :ref => 'trace'
     end
   end

   @engine.register_participant :first do |wi|
     sleep stash[:first_time]
     wi.fields['result'] = 'first'
   end

   @engine.register_participant :second do |wi|
     sleep stash[:second_time]
     wi.fields['result'] = 'second'
   end

   @engine.register_participant :trace do |wi|
     @tracer << "#{wi.fields['result']}"
   end

   wfid = @engine.launch(pdef)
   @engine.wait_for(wfid)

   wfid
 end
end

