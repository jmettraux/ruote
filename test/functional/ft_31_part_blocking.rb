
#
# testing ruote
#
# Fri Sep 25 16:15:57 JST 2009
#
# By David Goldhirsch
#

require File.expand_path('../base', __FILE__)

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

 def run_engine(options={})

   @dashboard.context.stash[:first_time] = options[:first_time] || 0.0
   @dashboard.context.stash[:second_time] = options[:second_time] || 0.0

   if @dashboard.context.stash[:first_time] == @dashboard.context.stash[:second_time]
     @dashboard.context.stash[:second_time] = @dashboard.context.stash[:first_time] + 0.1
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

   @dashboard.register_participant :first do |wi|
     sleep stash[:first_time]
     wi.fields['result'] = 'first'
   end

   @dashboard.register_participant :second do |wi|
     sleep stash[:second_time]
     wi.fields['result'] = 'second'
   end

   @dashboard.register_participant :trace do |wi|
     tracer << "#{wi.fields['result']}"
   end

   wfid = @dashboard.launch(pdef)
   @dashboard.wait_for(wfid)

   wfid
 end
end

